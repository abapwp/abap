FUNCTION zfm_sd004.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(I_MATNR) TYPE  MATNR OPTIONAL
*"     VALUE(I_KSCHL) TYPE  KSCHL OPTIONAL
*"     VALUE(I_VKORG) TYPE  VKORG OPTIONAL
*"     VALUE(I_VTWEG) TYPE  VTWEG OPTIONAL
*"     VALUE(I_CONFIG) TYPE  CHAR2 OPTIONAL
*"  EXPORTING
*"     VALUE(STATUS) TYPE  CHAR1
*"     VALUE(MESSAGE) TYPE  CHAR255
*"  TABLES
*"      ZT_PRICE_DATA STRUCTURE  ZSSD004_PRICE OPTIONAL
*"----------------------------------------------------------------------
  DATA:lv_kunnr  TYPE kna1-kunnr,
       lv_matnr  TYPE mvke-matnr,
       lv_vkorg  TYPE mvke-vkorg,
       lv_vtweg  TYPE mvke-vtweg,
       lv_kschl  TYPE konh-kschl,
       lv_knumh  TYPE konh-knumh,
       lv_msgfn  TYPE msgfn,
       lv_datbi  TYPE konh-datbi,
       lv_datab  TYPE konh-datab,
       lv_kbetr  TYPE konp-kbetr,
       lv_konwa  TYPE konp-konwa,
       lv_tabix  TYPE sy-tabix,
       lv_task   TYPE cvis_bp_general-object_task,
       lv_varkey TYPE char100,
       lv_tab    TYPE char3,
       lv_meins  TYPE meins.

  FIELD-SYMBOLS <fs> TYPE any.

  DATA: lt_bapicondct  TYPE TABLE OF bapicondct, "条件表的 BAPI 结构
        ls_bapicondct  TYPE  bapicondct,

        lt_bapicondhd  TYPE TABLE OF bapicondhd, "有英语字段名称的 KONH 的 BAPI 结构
        ls_bapicondhd  TYPE  bapicondhd,

        lt_bapicondit  TYPE TABLE OF bapicondit, "有英语字段名称的 KONP 的 BAPI 结构
        ls_bapicondit  TYPE  bapicondit,

        lt_bapicondqs  TYPE TABLE OF bapicondqs, "有英语字段名称的 KONM 的 BAPI 结构
        ls_bapicondqs  TYPE  bapicondqs,

        lt_bapicondvs  TYPE TABLE OF bapicondvs, "有英语字段名称的 KONW 的 BAPI 结构
        ls_bapicondvs  TYPE  bapicondvs,

        lt_bapiret2    TYPE TABLE OF bapiret2,
        ls_bapiret2    TYPE bapiret2,

        lt_bapiknumhs  TYPE TABLE OF bapiknumhs, "KNUMH分配的BAPI结构
        lt_mem_initial TYPE TABLE OF cnd_mem_initial, "条件: 初始上载缓冲

        ls_a304        TYPE a304, "具有审批状态的物料
        ls_a305        TYPE a305, "具有审批状态的客户/物料
        ls_a307        TYPE a307. "具有审批状态的客户

  "必输校验参数
  DATA: BEGIN OF lt_feild OCCURS 0,
          field TYPE fieldname,
        END OF lt_feild.
  DATA : lv_status TYPE bapibapi_mtype.
  DATA : lv_msg TYPE bapibapi_msg.
  DATA :lt_check TYPE TABLE OF zssd004_price WITH HEADER LINE.

  DATA:lv_guid TYPE sysuuid_c32.

*&--------------------------校验输入数据---------------------------
  IF ( i_config = '20' OR i_config = '40' ) AND i_matnr = ''.
    status = 'E'.
    message = '当业务操作为20/40时必须输入物料编码！'.
  ENDIF.
  IF i_config <> '10' AND i_config <> '20' AND i_config <> '40' AND i_config <> '50'.
    IF message IS INITIAL.
      status = 'E'.
      message = '业务操作只能是10/20/40/50!'.
    ELSE.
      message = message && '业务操作只能是10/20/40/50!'.
    ENDIF.
  ENDIF.

  CHECK status <> 'E'.

  IF i_config = '10' OR i_config = '20' OR i_config = '40' .
*************************************存日志表****************************************
    lv_guid = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
    DATA:gtsd_price_log TYPE TABLE OF ztsd_price_log WITH HEADER LINE.
    gtsd_price_log[] = CORRESPONDING #( zt_price_data[] ).
    LOOP AT gtsd_price_log .
      gtsd_price_log-zguid     = lv_guid .
      gtsd_price_log-zno_log   = sy-tabix .
      gtsd_price_log-zdate_log = sy-datum .
      gtsd_price_log-ztime_log = sy-uzeit .
      gtsd_price_log-zitype    = 'I' .
      MODIFY gtsd_price_log.
    ENDLOOP.
    MODIFY ztsd_price_log FROM TABLE gtsd_price_log.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.

    LOOP AT zt_price_data.
*&-----------初始化
      CLEAR: lv_kunnr,
             lv_matnr,
             lv_vkorg,
             lv_vtweg,
             lv_kschl,
             lv_knumh,
             lv_msgfn,
             lv_datbi,
             lv_datab,
             lv_kbetr,
             lv_konwa,
             lv_tabix,
             lv_task,
             lv_varkey,
             lv_tab,
             lv_meins.
      CLEAR: ls_bapicondct,
             ls_bapicondhd,
             ls_bapicondit,
             ls_bapicondqs,
             ls_bapicondvs.
      FREE:  lt_bapicondct,
             lt_bapicondhd,
             lt_bapicondit,
             lt_bapicondqs,
             lt_bapicondvs.

*&-------------------校验数据必输----------------------------
      FREE lt_check.
      MOVE-CORRESPONDING zt_price_data TO lt_check.
      APPEND lt_check.

      lt_feild[] = VALUE #(
                           ( field = 'KSCHL' )  " 条件类型
                           ( field = 'VKORG' )  " 销售组织
                           ( field = 'VTWEG' )  " 分销渠道
                           ( field = 'KBETR' )  " 条件金额
                           ( field = 'KPEIN' )  " 条件单位
                           ( field = 'DATAB' )  " 有效起始日
                           ( field = 'DATBI' )  " 有效截止日期
                         ).

      IF zt_price_data-kschl = 'ZPR0' AND zt_price_data-matnr IS INITIAL.
        APPEND VALUE #( field = 'MATNR' ) TO lt_feild[].
      ENDIF.
      IF zt_price_data-kschl = 'Z001' AND zt_price_data-kunnr IS INITIAL.
        APPEND VALUE #( field = 'KUNNR' ) TO lt_feild[].
      ENDIF.
      IF i_config = '40' AND zt_price_data-loevm_ko IS INITIAL.
        APPEND VALUE #( field = 'LOEVM_KO' ) TO lt_feild[].
      ENDIF.

      " 开始校验
      CLEAR : lv_status,lv_msg.
      CALL FUNCTION 'ZFM_CHECK_FEILD'
        IMPORTING
          ev_status  = lv_status
          ev_message = lv_msg
        TABLES
          gt_feild   = lt_feild[]
          gt_table   = lt_check[].

      lv_tabix = sy-tabix.
      lv_kschl = |{ zt_price_data-kschl ALPHA = IN }|."条件类型
      lv_kunnr = |{ zt_price_data-kunnr ALPHA = IN }|."客户
      lv_vkorg = |{ zt_price_data-vkorg ALPHA = IN }|."销售组织
      lv_vtweg = |{ zt_price_data-vtweg ALPHA = IN }|."分销渠道
      lv_matnr = |{ zt_price_data-matnr ALPHA = IN }|."物料
      lv_kbetr = zt_price_data-kbetr."条件金额
      lv_konwa = zt_price_data-kpein."条件单位
      lv_datab = zt_price_data-datab."有效起始日
      lv_datbi = zt_price_data-datbi."有效截止日期

      IF zt_price_data-kunnr IS NOT INITIAL.
        SELECT SINGLE COUNT(*) FROM kna1 WHERE kunnr EQ lv_kunnr.
        IF sy-subrc NE 0.
          IF lv_msg IS INITIAL.
            lv_msg = '客户不存在'.
          ELSE.
            lv_msg = lv_msg && '、客户不存在'.
          ENDIF.
        ENDIF.
      ENDIF.

      IF zt_price_data-vkorg IS NOT INITIAL.
        SELECT SINGLE COUNT(*) FROM tvko WHERE vkorg EQ lv_vkorg.
        IF sy-subrc NE 0.
          IF lv_msg IS INITIAL.
            lv_msg = '销售组织不存在'.
          ELSE.
            lv_msg = lv_msg && '、销售组织不存在'.
          ENDIF.
        ENDIF.
      ENDIF.

      IF zt_price_data-vtweg IS NOT INITIAL.
        SELECT SINGLE COUNT(*) FROM tvtw WHERE vtweg EQ lv_vtweg.
        IF sy-subrc NE 0.
          IF lv_msg IS INITIAL.
            lv_msg = '分销渠道不存在'.
          ELSE.
            lv_msg = lv_msg && '、分销渠道不存在'.
          ENDIF.
        ENDIF.
      ENDIF.

      IF lv_kschl EQ 'ZPR0' OR ( lv_kschl EQ 'Z001' AND lv_matnr IS NOT INITIAL ).
        SELECT SINGLE meins INTO lv_meins FROM mara WHERE matnr EQ lv_matnr.
        SELECT SINGLE COUNT(*) FROM mvke WHERE matnr EQ lv_matnr AND vkorg EQ lv_vkorg AND vtweg EQ lv_vtweg.
        IF sy-subrc NE 0.
          IF lv_msg IS INITIAL.
            lv_msg = '物料在' && lv_matnr && '销售组织' && lv_vkorg &&'分销渠道' && lv_vtweg && '视图中不存在'.
          ELSE.
            lv_msg = lv_msg && '、物料在' && lv_matnr && '销售组织' && lv_vkorg &&'分销渠道' && lv_vtweg && '视图中不存在'.
          ENDIF.
        ENDIF.
      ENDIF.

      IF lv_msg IS NOT INITIAL.
        zt_price_data-type = 'E'.
        zt_price_data-message = lv_msg.
        MODIFY zt_price_data INDEX lv_tabix TRANSPORTING type message.
      ELSE.
        IF zt_price_data-kschl EQ 'ZPR0' AND zt_price_data-kunnr IS INITIAL."304
          lv_tab = '304'.
          SELECT SINGLE * FROM a304 INTO ls_a304 WHERE kappl EQ 'V' AND kschl EQ lv_kschl AND vkorg EQ lv_vkorg AND vtweg EQ lv_vtweg AND matnr EQ lv_matnr AND datbi EQ lv_datbi.
          IF ls_a304 IS NOT INITIAL.
            lv_task = 'M'.
            lv_knumh = ls_a304-knumh.
            lv_msgfn = '004'.
          ELSE.
            lv_task = 'I'.
            lv_knumh = '$000000001'.
            lv_msgfn = '009'.
          ENDIF.
        ELSEIF zt_price_data-kschl EQ 'Z001' AND zt_price_data-matnr IS INITIAL."307
          lv_tab = '307'.
          SELECT SINGLE *  FROM a307 INTO ls_a307 WHERE kappl EQ 'V' AND kschl EQ lv_kschl AND vkorg EQ lv_vkorg AND vtweg EQ lv_vtweg AND kunnr EQ lv_kunnr AND datbi EQ lv_datbi.
          IF ls_a307 IS NOT INITIAL.
            lv_task = 'M'.
            lv_knumh = ls_a307-knumh.
            lv_msgfn = '004'.
          ELSE.
            lv_task = 'I'.
            lv_knumh = '$000000001'.
            lv_msgfn = '009'.
          ENDIF.
        ELSEIF ( zt_price_data-kschl EQ 'ZPR0' AND zt_price_data-kunnr IS NOT INITIAL ) OR ( zt_price_data-kschl EQ 'Z001' AND zt_price_data-matnr IS NOT INITIAL )."305
          lv_tab = '305'.
          SELECT SINGLE * FROM a305 INTO ls_a305 WHERE kappl EQ 'V' AND kschl EQ lv_kschl AND vkorg EQ lv_vkorg AND vtweg EQ lv_vtweg AND kunnr EQ lv_kunnr AND matnr EQ lv_matnr AND datbi EQ lv_datbi.
          IF ls_a305 IS NOT INITIAL.
            lv_task = 'M'.
            lv_knumh = ls_a305-knumh.
            lv_msgfn = '004'.
          ELSE.
            lv_task = 'I'.
            lv_knumh = '$000000001'.
            lv_msgfn = '009'.
          ENDIF.
        ENDIF.

*       传输状态：10 新增 20 修改 40 删除
        IF i_config = '10'.
          IF lv_task = 'I'.
            zt_price_data-type = 'E'.
            zt_price_data-message = '价格主数据在有效截止日期内存在价格，不允许创建！'.
          ENDIF.
        ELSEIF i_config = '20'.
          IF lv_task = 'I'.
            zt_price_data-type = 'E'.
            zt_price_data-message = '价格主数据不存在不能修改！'.
          ENDIF.
        ELSEIF i_config = '40'.
          IF lv_task = 'I'.
            zt_price_data-type = 'E'.
            zt_price_data-message = '价格主数据不存在不能删除！'.
          ENDIF.
        ENDIF.
        MODIFY zt_price_data INDEX lv_tabix TRANSPORTING type message.
      ENDIF.

      IF zt_price_data-type IS INITIAL.
        CASE lv_tab.
          WHEN '304'.
            CONCATENATE lv_vkorg lv_vtweg lv_matnr INTO lv_varkey.
          WHEN '305'.
            CONCATENATE lv_vkorg lv_vtweg lv_kunnr lv_matnr INTO lv_varkey.
          WHEN '307'.
            CONCATENATE lv_vkorg lv_vtweg lv_kunnr INTO lv_varkey.
            lv_meins = 'ST'.
        ENDCASE.

*&--------------------------新增-----------------------
        IF lv_task EQ 'I'.
          ls_bapicondct-operation  = lv_msgfn.        "消息功能： 003 删除; 004 修改 ;005 取代 ; 009 创建
          ls_bapicondct-cond_usage = 'A'.             "条件表用途: 'A'定价       相关见T681表
          ls_bapicondct-table_no   = lv_tab.          "条件表编号                相关见T681表
          ls_bapicondct-applicatio = 'V'.             "应用程序：'V' 销售/分销   相关见T681表
          ls_bapicondct-cond_type  = lv_kschl.        "条件类型
          ls_bapicondct-varkey     = lv_varkey.
          ls_bapicondct-valid_to   = lv_datbi.        "有效起始日
          ls_bapicondct-valid_from = lv_datab.        "有效截止日期
          ls_bapicondct-cond_no    = lv_knumh.        "条件记录编号
          APPEND ls_bapicondct TO lt_bapicondct.

          ls_bapicondhd-operation  = lv_msgfn.         "功能
          ls_bapicondhd-cond_no    = lv_knumh.         "条件记录编号
          ls_bapicondhd-created_by = sy-uname.         "创建人
          ls_bapicondhd-creat_date = sy-datum.         "创建日期
          ls_bapicondhd-cond_usage = 'A'.              "条件表用途: 'A'定价
          ls_bapicondhd-table_no   = lv_tab.           "
          ls_bapicondhd-applicatio = 'V'.              "应用程序：'V' 销售/分销
          ls_bapicondhd-cond_type  = lv_kschl.         "条件类型
          ls_bapicondhd-varkey     = lv_varkey.
          ls_bapicondhd-valid_to   = lv_datbi.         "有效起始日
          ls_bapicondhd-valid_from = lv_datab.         "有效截止日期
          APPEND ls_bapicondhd TO lt_bapicondhd .

          ls_bapicondit-operation  = lv_msgfn.         "功能
          ls_bapicondit-cond_no    = lv_knumh.         "条件记录编号
          ls_bapicondit-cond_count = lv_tabix.         "条件的序列号
          ls_bapicondit-applicatio = 'V'.              "应用程序：'V' 销售/分销
          ls_bapicondit-cond_type  = lv_kschl.         "条件类型
          ls_bapicondit-scaletype  = 'A'.              "等级类型：'A' 基础等级

          IF lv_kschl EQ 'ZPR0'.
            ls_bapicondit-calctypcon = 'C'.           "条件的计算类型：'C' 数量  'A' 百分数
            ls_bapicondit-cond_p_unt = '1'.           "条件定价单位
            ls_bapicondit-cond_unit  = lv_meins.      "条件单位
            ls_bapicondit-unitmeasur = lv_meins.      "条件等级计量单位
          ELSE.
            ls_bapicondit-calctypcon = 'A'.           "条件的计算类型'C' 数量  'A' 百分数
          ENDIF.

          ls_bapicondit-cond_value = lv_kbetr.        "金额
          ls_bapicondit-condcurr   = lv_konwa.        "条件单位（货币或百分比）
          APPEND ls_bapicondit TO lt_bapicondit.      "

          ls_bapicondqs-operation  = lv_msgfn.        "功能
          ls_bapicondqs-cond_no    = lv_knumh.        "条件记录编号
          ls_bapicondqs-cond_count = lv_tabix.        "条件的序列号
          ls_bapicondqs-line_no    = '1'.             "行等级的当前号码
          ls_bapicondqs-currency   = lv_kbetr.        "货币金额
          ls_bapicondqs-cond_unit  = lv_meins.        "条件单位
          ls_bapicondqs-condcurr   = lv_konwa.        "条件单位（货币或百分比）
          APPEND ls_bapicondqs TO lt_bapicondqs.
*&----------------------------修改-----------------------
        ELSEIF lv_task EQ 'M'.
          ls_bapicondct-operation  = lv_msgfn.         "消息功能： 003 DEL ; 004 MODIFY ;005 REPLACE 009 INITIAL
          ls_bapicondct-cond_usage = 'A'.              "条件表用途: 'A' 定价
          ls_bapicondct-table_no   = lv_tab.
          ls_bapicondct-applicatio = 'V'.              "应用程序：'V'销售/分销
          ls_bapicondct-cond_type  = lv_kschl.         "条件类型
          ls_bapicondct-varkey     = lv_varkey.
          ls_bapicondct-valid_to   = lv_datbi.
          ls_bapicondct-valid_from = lv_datab.
          ls_bapicondct-cond_no    = lv_knumh.         "创建
          APPEND ls_bapicondct TO lt_bapicondct.

          ls_bapicondhd-operation  = lv_msgfn.
          ls_bapicondhd-cond_no    = lv_knumh.
          ls_bapicondhd-created_by = sy-uname.
          ls_bapicondhd-creat_date = sy-datum.
          ls_bapicondhd-cond_usage = 'A'.           "条件表用途: 'A'定价
          ls_bapicondhd-table_no   = lv_tab.
          ls_bapicondhd-applicatio = 'V'.
          ls_bapicondhd-cond_type  = lv_kschl.
          ls_bapicondhd-varkey     = lv_varkey.
          ls_bapicondhd-valid_to   = lv_datbi.
          ls_bapicondhd-valid_from = lv_datab.
          APPEND ls_bapicondhd TO lt_bapicondhd .

          ls_bapicondit-operation  = lv_msgfn.
          ls_bapicondit-cond_no    = lv_knumh.
          ls_bapicondit-cond_count = lv_tabix.
          ls_bapicondit-applicatio = 'V'.
          ls_bapicondit-cond_type  = lv_kschl.
          ls_bapicondit-scaletype  = 'A'.           "'A' 基础等级
          IF i_config = '40' AND zt_price_data-loevm_ko IS NOT INITIAL.
            ls_bapicondit-indidelete = 'X'.           "条件记录的删除标识
          ENDIF.

          IF lv_kschl EQ 'ZPR0'.
            ls_bapicondit-calctypcon = 'C'.           "'C' 数量  'A' 百分数
            ls_bapicondit-cond_p_unt = '1'.
            ls_bapicondit-cond_unit  = lv_meins.
            ls_bapicondit-unitmeasur = lv_meins.
          ELSE.
            ls_bapicondit-calctypcon = 'A'.           "'C' 数量  'A' 百分数
          ENDIF.

          ls_bapicondit-cond_value = lv_kbetr.
          ls_bapicondit-condcurr   = lv_konwa.
          APPEND ls_bapicondit TO lt_bapicondit  .

          ls_bapicondit-operation = '004'.
          ls_bapicondit-cond_no   = <fs>.
          ls_bapicondit-cond_count = lv_tabix.
          ls_bapicondit-applicatio = 'V'.
          ls_bapicondit-cond_type  = lv_kschl.
          ls_bapicondit-scaletype  = 'A'.           "'A' 基础等级

          IF lv_kschl EQ 'ZPR0'.
            ls_bapicondit-calctypcon = 'C'.           "'C' 数量  'A' 百分数
            ls_bapicondit-cond_p_unt = '1'.
            ls_bapicondit-cond_unit  = lv_meins.
            ls_bapicondit-unitmeasur = lv_meins.
          ELSE.
            ls_bapicondit-calctypcon = 'A'.           "'C' 数量  'A' 百分数
          ENDIF.

          ls_bapicondit-cond_value = lv_kbetr.
          ls_bapicondit-condcurr   = lv_konwa.
          APPEND ls_bapicondit TO lt_bapicondit.

          ls_bapicondqs-operation  = lv_msgfn.
          ls_bapicondqs-cond_no    = lv_knumh.
          ls_bapicondqs-cond_count = lv_tabix.
          ls_bapicondqs-line_no    = '1'.
          ls_bapicondqs-currency   = lv_kbetr.
          ls_bapicondqs-cond_unit  = lv_meins.
          ls_bapicondqs-condcurr   = lv_konwa.
          APPEND ls_bapicondqs TO lt_bapicondqs.
        ENDIF.

        CALL FUNCTION 'BAPI_PRICES_CONDITIONS'
          TABLES
            ti_bapicondct  = lt_bapicondct
            ti_bapicondhd  = lt_bapicondhd
            ti_bapicondit  = lt_bapicondit
            ti_bapicondqs  = lt_bapicondqs
            ti_bapicondvs  = lt_bapicondvs
            to_bapiret2    = lt_bapiret2
            to_bapiknumhs  = lt_bapiknumhs
            to_mem_initial = lt_mem_initial
          EXCEPTIONS
            update_error   = 1
            OTHERS         = 2.

        LOOP AT lt_bapiret2 INTO ls_bapiret2 WHERE type CA 'EAX'.
          lv_msg = lv_msg && ls_bapiret2-message.
        ENDLOOP.

        DATA:lv_message TYPE char50.

        IF lv_msg IS NOT INITIAL.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          IF i_config = '10'.
            lv_message = '价格主数据创建失败：'.
          ELSEIF i_config = '20'.
            lv_message = '价格主数据修改失败：'.
          ELSEIF i_config = '40'.
            lv_message = '价格主数据删除失败：'.
          ENDIF.
          zt_price_data-type    = 'E'.
          zt_price_data-message = lv_message && lv_msg.
          MODIFY zt_price_data INDEX lv_tabix TRANSPORTING type message.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.
          IF i_config = '10'.
            lv_message = '价格主数据创建成功！'.
          ELSEIF i_config = '20'.
            lv_message = '价格主数据修改成功！'.
          ELSEIF i_config = '40'.
            lv_message = '价格主数据删除成功！'.
          ENDIF.
          zt_price_data-type    = 'S'.
          zt_price_data-message = lv_message.
          zt_price_data-knumh   = lt_bapiknumhs[ 1 ]-cond_no_new.
          MODIFY zt_price_data INDEX lv_tabix TRANSPORTING knumh type message.
        ENDIF.
      ENDIF.

    ENDLOOP.
*************************************存日志表****************************************
    FREE gtsd_price_log.
    gtsd_price_log[] = CORRESPONDING #( zt_price_data[] ).
    LOOP AT gtsd_price_log .
      gtsd_price_log-zguid     = lv_guid .
      gtsd_price_log-zno_log   = sy-tabix .
      gtsd_price_log-zdate_log = sy-datum .
      gtsd_price_log-ztime_log = sy-uzeit .
      gtsd_price_log-zitype    = 'O' .
      MODIFY gtsd_price_log.
    ENDLOOP.
    MODIFY ztsd_price_log FROM TABLE gtsd_price_log.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.

  ELSE.
    RANGES:s_matnr FOR a305-matnr,
           s_kschl FOR a305-kschl,
           s_vkorg FOR a305-vkorg,
           s_vtweg FOR a305-vtweg.

    IF i_matnr <> ''.
      s_matnr-sign   = 'I'.
      s_matnr-option = 'EQ'.
      s_matnr-low    = i_matnr.
      APPEND s_matnr.
    ENDIF.
    IF i_kschl <> ''.
      s_kschl-sign   = 'I'.
      s_kschl-option = 'EQ'.
      s_kschl-low    = i_kschl.
      APPEND s_kschl.
    ENDIF.
    IF i_vkorg <> ''.
      s_vkorg-sign   = 'I'.
      s_vkorg-option = 'EQ'.
      s_vkorg-low    = i_vkorg.
      APPEND s_vkorg.
    ENDIF.
    IF i_vtweg <> ''.
      s_vtweg-sign   = 'I'.
      s_vtweg-option = 'EQ'.
      s_vtweg-low    = i_vtweg.
      APPEND s_vtweg.
    ENDIF.

    SELECT
      a305~knumh,
      a305~kschl,
      a305~vkorg,
      a305~vtweg,
      a305~matnr,
      a305~kunnr,
      a305~datab,
      a305~datbi,
      konp~kbetr,
      konp~kpein,
      konp~kmein,
      konp~loevm_ko
      INTO CORRESPONDING FIELDS OF TABLE @zt_price_data FROM a305
      INNER JOIN konp ON konp~knumh = a305~knumh
      WHERE a305~matnr IN @s_matnr
        AND a305~kschl IN @s_kschl
        AND a305~vkorg IN @s_vkorg
        AND a305~vtweg IN @s_vtweg.
  ENDIF.
ENDFUNCTION.
