FUNCTION zfm_sd005.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(I_CONFIG) TYPE  CHAR2
*"     VALUE(I_BSTNK) TYPE  BSTNK
*"     VALUE(I_VBELN) TYPE  VBELN_VL OPTIONAL
*"     VALUE(VBELN) TYPE  VBELN OPTIONAL
*"     VALUE(I_ZKDDH) TYPE  ZE_KDDH OPTIONAL
*"     VALUE(I_ZZXDH) TYPE  ZE_ZXDH OPTIONAL
*"     VALUE(I_ZWLGS) TYPE  ZE_WLGS OPTIONAL
*"     VALUE(I_ZDPMC) TYPE  ZE_DPMC OPTIONAL
*"     VALUE(I_WADAT) TYPE  WADAT OPTIONAL
*"     VALUE(I_TEXT) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(ZMESSAGE) TYPE  CHAR255
*"     VALUE(ZTYPE) TYPE  CHAR1
*"     VALUE(BSTNK) TYPE  BSTNK
*"     VALUE(ZKDDH) TYPE  ZE_KDDH
*"     VALUE(ZVBELN) TYPE  VBELN
*"  TABLES
*"      IN_LIPS STRUCTURE  ZSSD005_LIPS
*"      OUT_DATA STRUCTURE  ZSSD005_OUT
*"----------------------------------------------------------------------
*& Program Name     : ZFM_SD005
*& Title            : 交货单接口
*& Module Name      : SD
*& Sub-Module       :
*& Author           : ITL
*& Create Date      : 20220823


  "定义创建交货单的BAPI内表
  DATA: lt_sales_order_items LIKE  bapidlvreftosalesorder OCCURS 0 WITH HEADER LINE,
        lt_serial_numbers    LIKE  bapidlvserialnumber    OCCURS 0 WITH HEADER LINE,
        lt_extension_in      LIKE  bapiparex              OCCURS 0 WITH HEADER LINE,
        lt_deliveries        LIKE  bapishpdelivnumb       OCCURS 0 WITH HEADER LINE,
        lt_created_items     LIKE  bapidlvitemcreated     OCCURS 0 WITH HEADER LINE,
        lt_extension_out     LIKE  bapiparex              OCCURS 0 WITH HEADER LINE, "增强结构
        lt_return            LIKE  bapiret2               OCCURS 0 WITH HEADER LINE, "返回参数
        lv_num_deliveries    TYPE  bapidlvcreateheader-num_deliveries, "创建的凭证行
        lv_ship_point        TYPE  bapidlvcreateheader-ship_point,  "装运点/收货点
        lv_due_date          TYPE  bapidlvcreateheader-due_date,   "交货创建日期
        lv_dnno              TYPE  bapishpdelivnumb-deliv_numb.   "交货单号

  DATA: ls_header      LIKE bapiobdlvhdrchg,
        ls_header_cont LIKE bapiobdlvhdrctrlchg,
        ls_delivery    LIKE bapiobdlvhdrchg-deliv_numb,
        ls_item        TYPE bapiobdlvitemchg,
        lt_item        LIKE TABLE OF bapiobdlvitemchg WITH HEADER LINE,
        ls_item_con    TYPE bapiobdlvitemctrlchg,   "交货单行项目
        lt_item_con    LIKE TABLE OF bapiobdlvitemctrlchg WITH HEADER LINE. "交货单行项目
  DATA: lt_extension2 LIKE TABLE OF bapiext , "增强字段
        ls_extension2 LIKE bapiext.

  DATA: ls_headtxt LIKE thead, "长文本
        lt_tline   LIKE TABLE OF  tline, "文本描述
        ls_tline   LIKE tline,
        lv_posnr   TYPE lips-posnr.


  DATA it_header_deadlines TYPE STANDARD TABLE OF bapidlvdeadln WITH HEADER LINE."交货日期

  DATA: lt_bapiret2 LIKE TABLE OF bapiret2 WITH HEADER LINE,
        ls_bapiret2 LIKE bapiret2.
  DATA: lt_item_data_spl LIKE /spe/bapiobdlvitemchg OCCURS 0 WITH HEADER LINE.
  DATA: lt_item_org LIKE TABLE OF bapiobdlvitemorg WITH HEADER LINE.
  DATA: lt_bapiret3 LIKE TABLE OF bapiret2 WITH HEADER LINE.

  "更改拣配
  DATA:vbkok_wa  TYPE vbkok,
       vbpok_tab TYPE vbpok OCCURS 0 WITH HEADER LINE,
       lt_prott  TYPE prott OCCURS 0 WITH HEADER LINE.
  CLEAR: vbkok_wa, vbpok_tab.
  REFRESH: vbpok_tab.


  CLEAR:lt_sales_order_items,lt_serial_numbers,lt_extension_in,lt_deliveries,lt_created_items,
        lt_extension_out,lt_return,lv_num_deliveries,lv_ship_point,lv_due_date,lv_dnno.
  REFRESH:lt_sales_order_items[],lt_serial_numbers[],lt_extension_in[],lt_deliveries,
          lt_created_items,lt_extension_out,lt_return.

  " 业务操作 I_CONFIG 必填
  "IN_LIPS-BSTNK 必填
  "I_CONFIG创建、变更、取消及查询（10、20、30、50）
  IF i_config IS NOT INITIAL.
    CASE i_config.
      WHEN '10'."创建
        IF in_lips IS NOT INITIAL."校验明细

          LOOP AT in_lips.
            IF vbeln IS NOT INITIAL. "如果传如的订单号不是空
              lt_sales_order_items-ref_doc = vbeln.
            ELSE.
              SELECT SINGLE vbeln FROM vbak INTO @lt_sales_order_items-ref_doc
                WHERE bstnk = @i_bstnk.
            ENDIF.
            lt_sales_order_items-ref_item = in_lips-posnr.    "行项目
            lt_sales_order_items-dlv_qty    = in_lips-kwmeng. "订单数量
            lt_sales_order_items-sales_unit = in_lips-vrkme.  "销售单位
            APPEND lt_sales_order_items.
          ENDLOOP.

          CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
            EXPORTING
              due_date          = i_wadat    "交货日期
            IMPORTING
              delivery          = lv_dnno
              num_deliveries    = lv_num_deliveries
            TABLES
              sales_order_items = lt_sales_order_items
              return            = lt_return.

          IF lv_num_deliveries IS INITIAL .
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
              CONCATENATE zmessage lt_return-message INTO zmessage.
              ztype = 'E'.
            ENDLOOP.
            EXIT.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.
            ztype = 'S'.

            CLEAR:ls_headtxt.
            ls_headtxt-tdobject = 'VBBK'.
            "补前导0
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = lv_dnno
              IMPORTING
                output = lv_dnno.
            ls_headtxt-tdname = lv_dnno.
            ls_headtxt-tdid = '0002'.
            ls_headtxt-tdspras = '1'.

            ls_tline-tdformat = '*'.
            ls_tline-tdline = i_text.
            APPEND ls_tline TO lt_tline.

            "抬头文本
            CALL FUNCTION 'SAVE_TEXT'
              EXPORTING
                client          = sy-mandt
                header          = ls_headtxt
                savemode_direct = 'X'
              TABLES
                lines           = lt_tline
              EXCEPTIONS
                id              = 1
                language        = 2
                name            = 3
                object          = 4
                OTHERS          = 5.
            IF sy-subrc <> 0.
*             Implement suitable error handling here
            ENDIF.
          ENDIF.

*--------------------------------------------------------------------*
          "交货单的库存地点，增强字段等 需要交货单创建成功后在进行修改
          IF ztype = 'S'.
            "抬头字段
            ls_header-deliv_numb = lv_dnno .
            ls_delivery = lv_dnno .
            ls_header_cont-deliv_numb = lv_dnno.
            ls_header_cont-deliv_date_flg = 'X'."确认交货日期
            ls_header_cont-dock_flg = 'X'.    "确认日期

            "抬头增强字段
            CLEAR:lt_extension2[],lt_item[],lt_item_con[].
            CLEAR:ls_extension2.
            ls_extension2-field = 'ZBSTNK'.
            ls_extension2-param = 'LIKP'.
            ls_extension2-row   = 1.
            ls_extension2-value = i_bstnk."外围系统唯一流水号
            APPEND ls_extension2 TO lt_extension2.

            CLEAR:ls_extension2.
            ls_extension2-field = 'ZZXDH'.
            ls_extension2-param = 'LIKP'.
            ls_extension2-row   = 1.
            ls_extension2-value = i_zzxdh."装箱单号
            APPEND ls_extension2 TO lt_extension2.

            CLEAR:ls_extension2.
            ls_extension2-field = 'ZWLGS'.
            ls_extension2-param = 'LIKP'.
            ls_extension2-row   = 1.
            ls_extension2-value = i_zwlgs."物流公司
            APPEND ls_extension2 TO lt_extension2.

            CLEAR:ls_extension2.
            ls_extension2-field = 'ZKDDH'.
            ls_extension2-param = 'LIKP'.
            ls_extension2-row   = 1.
            ls_extension2-value = i_zkddh."快递单号
            APPEND ls_extension2 TO lt_extension2.

            CLEAR:ls_extension2.
            ls_extension2-field = 'ZDPMC'.
            ls_extension2-param = 'LIKP'.
            ls_extension2-row   = 1.
            ls_extension2-value = i_zdpmc."店铺名称/客户名称
            APPEND ls_extension2 TO lt_extension2.

            "行项目
            LOOP AT in_lips.
              ls_item-deliv_numb = lv_dnno.
              ls_item-deliv_item = ls_item-deliv_item  + 10.
              ls_item-material   = in_lips-matnr.  "物料
              ls_item-dlv_qty    = in_lips-kwmeng.  "实际已经交货数量
              ls_item-dlv_qty_imunit  = in_lips-kwmeng.  "以仓库保管单位级的实际交货数量
              ls_item-fact_unit_nom = 1.
              ls_item-fact_unit_denom = 1.
              APPEND ls_item TO lt_item.
              CLEAR ls_item.

              ls_item_con-deliv_numb = lv_dnno.
              ls_item_con-deliv_item = ls_item_con-deliv_item + 10.
              ls_item_con-chg_delqty = 'X'.        "修改交货数量
              APPEND ls_item_con TO lt_item_con.
              CLEAR ls_item_con.

              lt_item_data_spl-deliv_numb = lv_dnno.
              lt_item_data_spl-deliv_item = ls_item-deliv_item + 10.
              lt_item_data_spl-stge_loc   = in_lips-lgort. "库存地点
              APPEND lt_item_data_spl.
              CLEAR lt_item_data_spl.

              lt_item_org-deliv_numb = lv_dnno.
              lt_item_org-itm_number = lt_item_org-itm_number + 10.
              lt_item_org-plant      = in_lips-werks.    "工厂
              APPEND lt_item_org.
              CLEAR lt_item_org.

              CLEAR:ls_extension2.
              ls_extension2-field = 'ZCPXH'.
              ls_extension2-param = 'LIPS'.
              ls_extension2-row   = 10.
              ls_extension2-value = in_lips-zcpxh."产品型号
              APPEND ls_extension2 TO lt_extension2.

              CLEAR:ls_extension2.
              ls_extension2-field = 'ZWBXTBS'.
              ls_extension2-param = 'LIPS'.
              ls_extension2-row   = 10.
              ls_extension2-value = in_lips-zwbxtbs."平台订单号
              APPEND ls_extension2 TO lt_extension2.

            ENDLOOP.


            CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
              EXPORTING
                header_data    = ls_header
                header_control = ls_header_cont
                delivery       = ls_delivery
              TABLES
                item_data      = lt_item
                item_control   = lt_item_con
                extension2     = lt_extension2
                return         = lt_bapiret3
                item_data_spl  = lt_item_data_spl.

            LOOP AT lt_bapiret3 WHERE type = 'E' OR type = 'A'.
              CONCATENATE zmessage lt_bapiret3-message INTO zmessage.
              ztype = 'E'.
            ENDLOOP.
            IF sy-subrc <> 0.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
                EXPORTING
                  wait = 'X'.

*              "更改拣配
*              vbkok_wa-vbeln_vl = lv_dnno.
*              LOOP AT in_lips.
*                CLEAR: vbpok_tab.
*                vbpok_tab-vbeln_vl = lv_dnno.
*                vbpok_tab-posnr_vl = vbpok_tab-posnr_vl + 10.
*                vbpok_tab-vbeln = vbeln.
*                vbpok_tab-posnn = in_lips-posnr.
*                vbpok_tab-pikmg = in_lips-menge.
**              vbpok_tab-meins = in_lips-vrkme.
**              vbpok_tab-ndifm = 0.
**              vbpok_tab-pikmg = in_lips-menge.
*                APPEND vbpok_tab.
*              ENDLOOP.
*              "更改拣配数量
*              CALL FUNCTION 'SD_DELIVERY_UPDATE_PICKING'
*                EXPORTING
*                  vbkok_wa  = vbkok_wa
*                  synchron  = 'X'
*                TABLES
*                  vbpok_tab = vbpok_tab
*                  prot      = lt_prott.
*              LOOP AT lt_prott WHERE msgty = 'E' OR msgty = 'A'.
*                CONCATENATE zmessage lt_prott-msgv1 lt_prott-msgv2 lt_prott-msgv3 lt_prott-msgv4 INTO zmessage.
*                ztype = 'E'.
*              ENDLOOP.
*              IF sy-subrc <> 0.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
                EXPORTING
                  wait = 'X'.

              LOOP AT in_lips.
                CLEAR:ls_headtxt.
                ls_headtxt-tdobject = 'VBBP'.
                lv_posnr = lv_posnr + 10.
                ls_headtxt-tdname = lv_dnno && lv_posnr.
                ls_headtxt-tdid = '0003'.
                ls_headtxt-tdspras = '1'.

                CLEAR: ls_tline,lt_tline.
                ls_tline-tdformat = '*'.
                ls_tline-tdline = in_lips-ztxt.
                APPEND ls_tline TO lt_tline.

                "行项目文本
                CALL FUNCTION 'SAVE_TEXT'
                  EXPORTING
                    client          = sy-mandt
                    header          = ls_headtxt
                    savemode_direct = 'X'
                  TABLES
                    lines           = lt_tline
                  EXCEPTIONS
                    id              = 1
                    language        = 2
                    name            = 3
                    object          = 4
                    OTHERS          = 5.
                IF sy-subrc <> 0.
*             Implement suitable error handling here
                ENDIF.
              ENDLOOP.

              ztype = 'S'.             "返回状态
              zmessage = '创建成功'.   "返回消息
              zvbeln = lv_dnno.        "交货单号
              bstnk = i_bstnk.        "外围系统唯一流水

              SELECT likp~zbstnk
                     likp~vbeln
                     likp~lfart
                     likp~kunnr
                     likp~zkddh
                     lips~posnr
                     lips~matnr
                     lips~lfimg AS kwmeng
                     lips~vrkme
                     likp~werks
                     lips~lgort
                     likp~waerk
                     lips~zcpxh  FROM likp
                INNER JOIN lips ON likp~vbeln = lips~vbeln
                INTO CORRESPONDING FIELDS OF TABLE out_data
                WHERE likp~vbeln = lv_dnno.
*              ENDIF.
            ENDIF.
          ENDIF.
        ELSE.
          zmessage = '创建交货单,行项目不能为空.'.
          ztype  = 'E'.
          RETURN.
        ENDIF.
      WHEN '20'."修改
        IF in_lips IS NOT INITIAL."校验明细
          IF i_vbeln IS NOT INITIAL."有交货单号
            lv_dnno = i_vbeln.
          ELSE.
            SELECT SINGLE vbeln FROM likp WHERE zbstnk = @i_bstnk INTO @lv_dnno.
          ENDIF.
          "补前导0
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = lv_dnno
            IMPORTING
              output = lv_dnno.

          "抬头字段
          ls_header-deliv_numb = lv_dnno .
          ls_delivery = lv_dnno .
          ls_header_cont-deliv_numb = lv_dnno.
          ls_header_cont-deliv_date_flg = 'X'."确认交货日期
          ls_header_cont-dock_flg = 'X'.    "确认日期

          "抬头增强字段
          CLEAR:lt_extension2[],lt_item[],lt_item_con[].
          CLEAR:ls_extension2.
          ls_extension2-field = 'ZBSTNK'.
          ls_extension2-param = 'LIKP'.
          ls_extension2-row   = 1.
          ls_extension2-value = i_bstnk."外围系统唯一流水号
          APPEND ls_extension2 TO lt_extension2.

          CLEAR:ls_extension2.
          ls_extension2-field = 'ZZXDH'.
          ls_extension2-param = 'LIKP'.
          ls_extension2-row   = 1.
          ls_extension2-value = i_zzxdh."装箱单号
          APPEND ls_extension2 TO lt_extension2.

          CLEAR:ls_extension2.
          ls_extension2-field = 'ZWLGS'.
          ls_extension2-param = 'LIKP'.
          ls_extension2-row   = 1.
          ls_extension2-value = i_zwlgs."物流公司
          APPEND ls_extension2 TO lt_extension2.

          CLEAR:ls_extension2.
          ls_extension2-field = 'ZKDDH'.
          ls_extension2-param = 'LIKP'.
          ls_extension2-row   = 1.
          ls_extension2-value = i_zkddh."快递单号
          APPEND ls_extension2 TO lt_extension2.

          CLEAR:ls_extension2.
          ls_extension2-field = 'ZDPMC'.
          ls_extension2-param = 'LIKP'.
          ls_extension2-row   = 1.
          ls_extension2-value = i_zdpmc."店铺名称/客户名称
          APPEND ls_extension2 TO lt_extension2.

          "行项目
          LOOP AT in_lips.
            ls_item-deliv_numb = lv_dnno.
            ls_item-deliv_item = ls_item-deliv_item  + 10.
            ls_item-material   = in_lips-matnr.  "物料
            ls_item-dlv_qty    = in_lips-kwmeng.  "实际已经交货数量
            ls_item-dlv_qty_imunit  = in_lips-kwmeng.  "以仓库保管单位级的实际交货数量
            ls_item-fact_unit_nom = 1.
            ls_item-fact_unit_denom = 1.
            APPEND ls_item TO lt_item.
            CLEAR ls_item.

            ls_item_con-deliv_numb = lv_dnno.
            ls_item_con-deliv_item = ls_item_con-deliv_item + 10.
            ls_item_con-chg_delqty = 'X'.        "修改交货数量
            APPEND ls_item_con TO lt_item_con.
            CLEAR ls_item_con.

            lt_item_data_spl-deliv_numb = lv_dnno.
            lt_item_data_spl-deliv_item = ls_item-deliv_item + 10.
            lt_item_data_spl-stge_loc   = in_lips-lgort. "库存地点
            APPEND lt_item_data_spl.
            CLEAR lt_item_data_spl.

            lt_item_org-deliv_numb = lv_dnno.
            lt_item_org-itm_number = lt_item_org-itm_number + 10.
            lt_item_org-plant      = in_lips-werks.    "工厂
            APPEND lt_item_org.
            CLEAR lt_item_org.

            CLEAR:ls_extension2.
            ls_extension2-field = 'ZCPXH'.
            ls_extension2-param = 'LIPS'.
            ls_extension2-row   = 10.
            ls_extension2-value = in_lips-zcpxh."产品型号
            APPEND ls_extension2 TO lt_extension2.

            CLEAR:ls_extension2.
            ls_extension2-field = 'ZWBXTBS'.
            ls_extension2-param = 'LIPS'.
            ls_extension2-row   = 10.
            ls_extension2-value = in_lips-zwbxtbs."平台订单号
            APPEND ls_extension2 TO lt_extension2.

          ENDLOOP.


          CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
            EXPORTING
              header_data    = ls_header
              header_control = ls_header_cont
              delivery       = ls_delivery
            TABLES
              item_data      = lt_item
              item_control   = lt_item_con
              extension2     = lt_extension2
              return         = lt_bapiret3
              item_data_spl  = lt_item_data_spl.

          LOOP AT lt_bapiret3 WHERE type = 'E' OR type = 'A'.
            CONCATENATE zmessage lt_bapiret3-message INTO zmessage.
            ztype = 'E'.
          ENDLOOP.
          IF sy-subrc <> 0.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.

*            "更改拣配
*            vbkok_wa-vbeln_vl = lv_dnno.
*            LOOP AT in_lips.
*              CLEAR: vbpok_tab.
*              vbpok_tab-vbeln_vl = lv_dnno.
*              vbpok_tab-posnr_vl = vbpok_tab-posnr_vl + 10.
*              vbpok_tab-vbeln = vbeln.
*              vbpok_tab-posnn = in_lips-posnr.
*              vbpok_tab-pikmg = in_lips-menge.
**              vbpok_tab-meins = in_lips-vrkme.
**              vbpok_tab-ndifm = 0.
**              vbpok_tab-pikmg = in_lips-menge.
*              APPEND vbpok_tab.
*            ENDLOOP.
*            "更改拣配数量
*            CALL FUNCTION 'SD_DELIVERY_UPDATE_PICKING'
*              EXPORTING
*                vbkok_wa  = vbkok_wa
*                synchron  = 'X'
*              TABLES
*                vbpok_tab = vbpok_tab
*                prot      = lt_prott.
*            LOOP AT lt_prott WHERE msgty = 'E' OR msgty = 'A'.
*              CONCATENATE zmessage lt_prott-msgv1 lt_prott-msgv2 lt_prott-msgv3 lt_prott-msgv4 INTO zmessage.
*              ztype = 'E'.
*            ENDLOOP.
*            IF sy-subrc <> 0.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.

            LOOP AT in_lips.
              CLEAR:ls_headtxt.
              ls_headtxt-tdobject = 'VBBP'.
              lv_posnr = lv_posnr + 10.
              ls_headtxt-tdname = lv_dnno && lv_posnr.
              ls_headtxt-tdid = '0003'.
              ls_headtxt-tdspras = '1'.

              CLEAR: ls_tline,lt_tline.
              ls_tline-tdformat = '*'.
              ls_tline-tdline = in_lips-ztxt.
              APPEND ls_tline TO lt_tline.

              "行项目文本
              CALL FUNCTION 'SAVE_TEXT'
                EXPORTING
                  client          = sy-mandt
                  header          = ls_headtxt
                  savemode_direct = 'X'
                TABLES
                  lines           = lt_tline
                EXCEPTIONS
                  id              = 1
                  language        = 2
                  name            = 3
                  object          = 4
                  OTHERS          = 5.
              IF sy-subrc <> 0.
*             Implement suitable error handling here
              ENDIF.
            ENDLOOP.

            ztype = 'S'.             "返回状态
            zmessage = '修改成功'.   "返回消息
            zvbeln = lv_dnno.        "交货单号
            bstnk = i_bstnk.        "外围系统唯一流水
*            ENDIF.

          ENDIF.
        ELSE.
          zmessage = '修改交货单,行项目不能为空.'.
          ztype  = 'E'.
          RETURN.
        ENDIF.

      WHEN '30'."取消 给删除标识  不是冲销
        IF in_lips IS NOT INITIAL."校验明细
          IF i_vbeln IS NOT INITIAL."有交货单号
            lv_dnno = i_vbeln.
          ELSE.
            SELECT SINGLE vbeln FROM likp WHERE zbstnk = @i_bstnk INTO @lv_dnno.
          ENDIF.
          "补前导0
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = lv_dnno
            IMPORTING
              output = lv_dnno.
          ls_header-deliv_numb = lv_dnno .
          ls_header_cont-deliv_numb = lv_dnno.
          ls_delivery = lv_dnno.
          LOOP AT in_lips.
            ls_item-deliv_numb = lv_dnno.
            ls_item-deliv_item = ls_item-deliv_item  + 10.
            ls_item-material   = in_lips-matnr.  "物料
            ls_item-dlv_qty    = in_lips-kwmeng.  "实际已经交货数量
            ls_item-dlv_qty_imunit  = in_lips-kwmeng.  "以仓库保管单位级的实际交货数量
            ls_item-fact_unit_nom = 1.
            ls_item-fact_unit_denom = 1.
            APPEND ls_item TO lt_item.
            CLEAR ls_item.

            CLEAR ls_item_con.
            ls_item_con-deliv_numb = lv_dnno.
            ls_item_con-deliv_item = ls_item_con-deliv_item + 10.
            ls_item_con-del_item = 'X'.        "删除标识
            APPEND ls_item_con TO lt_item_con.
          ENDLOOP.

          CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
            EXPORTING
              header_data    = ls_header
              header_control = ls_header_cont
              delivery       = ls_delivery
            TABLES
              item_data      = lt_item
              item_control   = lt_item_con
              extension2     = lt_extension2
              return         = lt_bapiret3
              item_data_spl  = lt_item_data_spl.
          LOOP AT lt_bapiret3 WHERE type = 'E' OR type = 'A'.
            CONCATENATE zmessage lt_bapiret3-message INTO zmessage.
            ztype = 'E'.
          ENDLOOP.
          IF sy-subrc <> 0.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.
            zmessage = '删除成功'.
            ztype = 'S'.
            zvbeln = lv_dnno. "交货单号
          ENDIF.
        ELSE.
          zmessage = '删除交货单,行项目不能为空.'.
          ztype  = 'E'.
          RETURN.
        ENDIF.
      WHEN '50'."查询
        SELECT likp~zbstnk
               likp~vbeln
               likp~lfart
               likp~kunnr
               likp~zkddh
               lips~posnr
               lips~matnr
               lips~lfimg AS kwmeng
               lips~vrkme
               likp~werks
               lips~lgort
               likp~waerk
               lips~zcpxh  FROM likp
          INNER JOIN lips ON likp~vbeln = lips~vbeln
          INTO CORRESPONDING FIELDS OF TABLE out_data
          WHERE likp~vbeln = i_vbeln
            AND zkddh = i_zkddh
            AND zbstnk = i_bstnk.
        IF out_data[] IS NOT INITIAL.
          zmessage = '成功'.
          ztype  = 'S'.
        ELSE.
          zmessage = '未查到交货单'.
          ztype  = 'E'.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.
  ELSE.
    zmessage = '业务操作未传.'.
    ztype  = 'E'.
    RETURN.
  ENDIF.


ENDFUNCTION.
