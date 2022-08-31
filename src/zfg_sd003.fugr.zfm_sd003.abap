FUNCTION zfm_sd003.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(I_CONFIG) TYPE  ZCONGIG
*"     VALUE(I_VBAK_TAB) TYPE  ZTTSD003_VBAK
*"     VALUE(I_VBAP_TAB) TYPE  ZTTSD003_VBAP
*"  TABLES
*"      O_MSG STRUCTURE  ZSSD003_C
*"----------------------------------------------------------------------
  DATA:
    lv_salesdocument TYPE bapivbeln-vbeln.
  DATA:
    ls_order_header_in  TYPE bapisdhd1,
    ls_order_header_inx TYPE bapisdhd1x.
  DATA:
    lv_salesdocument_ex  TYPE bapivbeln-vbeln.
  DATA:
    lt_return TYPE TABLE OF bapiret2,
    ls_return TYPE bapiret2.
  DATA:
    lt_sales_items_in  TYPE TABLE OF bapisditm,
    ls_sales_items_in  TYPE  bapisditm,
    lt_sales_items_inx TYPE TABLE OF bapisditmx,
    ls_sales_items_inx TYPE  bapisditmx.
  DATA:
    lt_sales_schedules_in  TYPE TABLE OF bapischdl,
    ls_sales_schedules_in  TYPE  bapischdl,
    lt_sales_schedules_inx TYPE TABLE OF bapischdlx,
    ls_sales_schedules_inx TYPE  bapischdlx.
  DATA:
    lt_sales_conditions_in  TYPE TABLE OF bapicond,
    ls_sales_conditions_in  TYPE  bapicond,
    lt_sales_conditions_inx TYPE TABLE OF bapicondx,
    ls_sales_conditions_inx TYPE  bapicondx.
  DATA:
    lt_sales_text TYPE TABLE OF bapisdtext,
    ls_sales_text TYPE  bapisdtext.
  DATA:
    lt_sales_partners TYPE TABLE OF bapiparnr,
    ls_sales_partners TYPE  bapiparnr.
  DATA:
    ls_msg TYPE zssd003_c.

  DATA:
    ls_order_header_in_c  TYPE bapisdh1,
    ls_order_header_inx_c TYPE bapisdh1x.
  DATA:
    ls_logic_switch TYPE bapisdls.
  "DATA: lv_id TYPE STRING.
  "bapi扩展
  DATA:ls_vbak_ex     TYPE bape_vbak,
       ls_vbap_ex     TYPE bape_vbap,
       ls_vbakx_ex    TYPE bape_vbakx,
       ls_vbapx_ex    TYPE bape_vbapx,
       lt_extension   TYPE TABLE OF bapiparex,
       ls_extension   TYPE bapiparex,
       lt_extension_u TYPE TABLE OF bapiparex,
       ls_extension_u TYPE bapiparex,
       lt_extensionx_u TYPE TABLE OF bapiparex,
       ls_extensionx_u TYPE bapiparex.


*********************************************************************
  "数据校验
*********************************************************************
  /afl/log_init.   "初始化日志

  LOOP AT i_vbak_tab INTO DATA(ls_vbak).
    "抬头数据校验
    IF ls_vbak-bstnk IS INITIAL .
      CLEAR ls_msg.
      ls_msg-message = '第' && sy-tabix && '行没有给出外部系统唯一流水号'.
      ls_msg-type = 'E'.
      ls_msg-bstnk = ls_vbak-bstnk.
      APPEND ls_msg TO o_msg.
      /afl/set_status 'E' ls_msg-message.    "更新日志
      CONTINUE.
    ENDIF.

    "抬头数据非空校验
    IF ls_vbak-auart IS INITIAL OR ls_vbak-kunnr IS INITIAL OR
       ls_vbak-vkorg IS INITIAL OR ls_vbak-vtweg IS INITIAL OR
       ls_vbak-vdatu IS INITIAL ."OR ls_vbak-ext_ref_doc_id IS INITIAL.
      CLEAR ls_msg.
      ls_msg-message = '流水号为' && ls_vbak-bstnk && '的关键数据缺失'.
      ls_msg-type = 'E'.
      ls_msg-bstnk = ls_vbak-bstnk.
      APPEND ls_msg TO o_msg.
      /afl/set_status 'E' ls_msg-message.
      CONTINUE.
    ENDIF.

    "行数据非空校验
    LOOP AT i_vbap_tab INTO DATA(ls_vbap) WHERE bstnk = ls_vbak-bstnk.
      IF ls_vbap-posnr  IS INITIAL OR ls_vbap-matnr IS INITIAL OR
         ls_vbap-kwmeng IS INITIAL OR "ls_vbap-kbetr IS INITIAL OR
         ls_vbap-netwr  IS INITIAL.
        CLEAR ls_msg.
        ls_msg-message = '流水号为' && ls_vbak-bstnk && '的行项目数据存在缺失'.
        ls_msg-type = 'E'.
        ls_msg-bstnk = ls_vbak-bstnk.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
        CONTINUE.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR ls_msg.
      ls_msg-message = '流水号为' && ls_vbak-bstnk && '没有行项目数据'.
      ls_msg-type = 'E'.
      ls_msg-bstnk = ls_vbak-bstnk.
      APPEND ls_msg TO o_msg.
      /afl/set_status 'E' ls_msg-message.
      CONTINUE.
    ENDIF.

    IF i_config = '20'.
      "修改订单必须给出订单号
      IF ls_vbak-vbeln IS INITIAL .
        CLEAR ls_msg.
        ls_msg-message = ls_vbak-bstnk && '的销售订单不允许为空'.
        ls_msg-type = 'E'.
        ls_msg-bstnk = ls_vbak-bstnk.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
        CONTINUE.
      ENDIF.
    ENDIF.
  ENDLOOP.

*********************************************************************
  "创建销售订单
*********************************************************************
  IF i_config = '10'.
    LOOP AT i_vbak_tab INTO ls_vbak.
      "若无错误则可开始订单创建流程
      READ TABLE o_msg INTO ls_msg WITH KEY bstnk = ls_vbak-bstnk.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      SELECT SINGLE * FROM ztsd_003 INTO @DATA(ls_ztsd003) WHERE bstnk = @ls_vbak-bstnk AND fail_key = ''.
      IF sy-subrc = 0.
        CLEAR ls_msg.
        ls_msg-message = '当前流水号已创建销售订单' && ls_ztsd003-vbeln && ',不可重复创建'.
        ls_msg-type = 'E'.
        ls_msg-bstnk = ls_vbak-bstnk.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
        CONTINUE.
      ELSE.
        ls_ztsd003-bstnk = ls_vbak-bstnk.
      ENDIF.

      REFRESH lt_sales_text.
      CLEAR ls_sales_text.
      ls_sales_text-text_id = '0001'.
      ls_sales_text-langu = sy-langu.
      ls_sales_text-text_line = ls_vbak-text1.
      APPEND ls_sales_text TO lt_sales_text.

      "抬头数据
      CLEAR lv_salesdocument.
      lv_salesdocument = ls_vbak-vbeln.
      CLEAR: ls_order_header_in ,ls_order_header_inx.
      ls_order_header_in-doc_type   = ls_vbak-auart.        "凭证类型
      ls_order_header_in-sales_org  = ls_vbak-vkorg.        "销售组织
      ls_order_header_in-distr_chan = ls_vbak-vtweg.        "分销渠道
      ls_order_header_in-req_date_h = ls_vbak-vdatu.        "需求交货日期
      ls_order_header_in-name       = ls_vbak-bname.        "联系人
      ls_order_header_in-telephone  = ls_vbak-telf1.        "联系电话
      ls_order_header_in-purch_no_c  = ls_vbak-bstnk.       "客户参考

      ls_order_header_inx-doc_type   = 'X'.
      ls_order_header_inx-sales_org  = 'X'.
      ls_order_header_inx-distr_chan = 'X'.
      ls_order_header_inx-req_date_h = 'X'.
      ls_order_header_inx-name       = 'X'.
      ls_order_header_inx-telephone  = 'X'.
      ls_order_header_inx-purch_no_c = 'X'.

      DATA: lv_string TYPE kna1-kunnr.
      CLEAR lv_string.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_vbak-kunnr
        IMPORTING
          output = lv_string.
      "角色
      REFRESH lt_sales_partners.
      CLEAR ls_sales_partners.
      ls_sales_partners-partn_role = 'WE'.
      ls_sales_partners-partn_numb = lv_string. "送达方
      APPEND ls_sales_partners TO lt_sales_partners.
      CLEAR ls_sales_partners.
      ls_sales_partners-partn_role = 'AG'.
      ls_sales_partners-partn_numb = lv_string. "售达方
      APPEND ls_sales_partners TO lt_sales_partners.
      CLEAR ls_sales_partners.
      ls_sales_partners-partn_role = 'RE'.
      ls_sales_partners-partn_numb = lv_string. "售达方
      APPEND ls_sales_partners TO lt_sales_partners.
      CLEAR ls_sales_partners.
      ls_sales_partners-partn_role = 'RG'.
      ls_sales_partners-partn_numb = lv_string. "售达方
      APPEND ls_sales_partners TO lt_sales_partners.

      "抬头extension
      CLEAR: ls_vbak_ex,ls_vbakx_ex.
      ls_vbak_ex-zxfzid = ls_vbak-zxfzid.
      ls_vbak_ex-zywy = ls_vbak-zywy.
      ls_vbak_ex-zshrq = ls_vbak-zshrq.
      ls_vbak_ex-zshr = ls_vbak-zshr.
      ls_vbak_ex-zshcllx = ls_vbak-zshcllx.
      ls_vbak_ex-zdz = ls_vbak-zdz.
      ls_vbak_ex-zgj = ls_vbak-zgj.
      ls_vbak_ex-zsheng = ls_vbak-zsheng.
      ls_vbak_ex-zshi = ls_vbak-zshi.
      ls_vbak_ex-zqx = ls_vbak-zqx.
      ls_vbak_ex-zxsdq = ls_vbak-zxsdq.
      ls_vbak_ex-zkhdj = ls_vbak-zkhdj.
      ls_vbak_ex-zfkfs = ls_vbak-zfkfs.
      ls_vbak_ex-zhth = ls_vbak-zhth.
      ls_vbak_ex-zwbxtbs = ls_vbak-zwbxtbs.
      ls_vbak_ex-zcjsj = ls_vbak-zcjsj.
      ls_vbak_ex-zfksj = ls_vbak-zfksj.
      ls_extension-structure = 'BAPE_VBAK'.
      ls_extension+30 = ls_vbak_ex.
      APPEND ls_extension TO lt_extension.
      CLEAR ls_extension.
      ls_vbakx_ex-zxfzid  = abap_true.
      ls_vbakx_ex-zywy    = abap_true.
      ls_vbakx_ex-zshrq   = abap_true.
      ls_vbakx_ex-zshr    = abap_true.
      ls_vbakx_ex-zshcllx = abap_true.
      ls_vbakx_ex-zdz     = abap_true.
      ls_vbakx_ex-zgj     = abap_true.
      ls_vbakx_ex-zsheng  = abap_true.
      ls_vbakx_ex-zshi    = abap_true.
      ls_vbakx_ex-zqx     = abap_true.
      ls_vbakx_ex-zxsdq   = abap_true.
      ls_vbakx_ex-zkhdj   = abap_true.
      ls_vbakx_ex-zfkfs   = abap_true.
      ls_vbakx_ex-zhth    = abap_true.
      ls_vbakx_ex-zwbxtbs = abap_true.
      ls_vbakx_ex-zcjsj   = abap_true.
      ls_vbakx_ex-zfksj   = abap_true.
      ls_extension-structure = 'BAPE_VBAKX'.
      ls_extension+30 = ls_vbakx_ex.
      APPEND ls_extension TO lt_extension.
      CLEAR ls_extension.

      "行数据
      REFRESH: lt_sales_items_in ,lt_sales_items_inx,
               lt_sales_schedules_in ,lt_sales_schedules_inx,
               lt_sales_conditions_in ,lt_sales_conditions_inx.

      LOOP AT i_vbap_tab INTO ls_vbap WHERE bstnk = ls_vbak-bstnk.

        CLEAR ls_sales_items_in.
        ls_sales_items_in-itm_number   = ls_vbap-posnr.   "行项目
        ls_sales_items_in-material     = ls_vbap-matnr.   "物料编码
        ls_sales_items_in-target_qty   = ls_vbap-kwmeng.  "数量
        ls_sales_items_in-plant        = ls_vbap-werks.   "工厂
        ls_sales_items_in-store_loc    = ls_vbap-lgort.   "库存地点
        ls_sales_items_in-reason_rej   = ls_vbap-abgru.   "拒绝原因
        IF ls_vbap-zmf = 'X'.
          ls_sales_items_in-item_categ   = 'TANN'.   "项目类型
        ENDIF.
        APPEND ls_sales_items_in TO lt_sales_items_in.

        CLEAR ls_sales_items_inx.
        ls_sales_items_inx-itm_number   = ls_vbap-posnr.
        ls_sales_items_inx-material     = 'X'.
        ls_sales_items_inx-target_qty   = 'X'.
        ls_sales_items_inx-plant        = 'X'.
        ls_sales_items_inx-store_loc    = 'X'.
        ls_sales_items_inx-reason_rej   = 'X'.
        ls_sales_items_inx-item_categ   = 'X'.
        APPEND ls_sales_items_inx TO lt_sales_items_inx.

        CLEAR ls_sales_schedules_in.
        ls_sales_schedules_in-itm_number = ls_vbap-posnr.
        ls_sales_schedules_in-req_qty    = ls_vbap-kwmeng.    "数量
        APPEND ls_sales_schedules_in TO lt_sales_schedules_in.

        CLEAR ls_sales_schedules_inx.
        ls_sales_schedules_inx-itm_number = ls_vbap-posnr.
        ls_sales_schedules_inx-req_qty    = 'X'.    "数量
        APPEND ls_sales_schedules_inx TO lt_sales_schedules_inx.

        IF ls_vbap-zmf <> 'X'.

          CLEAR ls_sales_conditions_in.
          ls_sales_conditions_in-itm_number  = ls_vbap-posnr.   "行项目
          ls_sales_conditions_in-currency    = ls_vbap-waerk.   "货币
          ls_sales_conditions_in-cond_value  = ls_vbap-kbetr.   "净值
          ls_sales_conditions_in-cond_type   = 'PR01'.          "类型
          ls_sales_conditions_in-cond_updat  = 'X'.

          APPEND ls_sales_conditions_in TO lt_sales_conditions_in.
          CLEAR ls_sales_conditions_inx.
          ls_sales_conditions_inx-itm_number = ls_vbap-posnr.
          ls_sales_conditions_inx-currency   = 'X'.
          ls_sales_conditions_inx-cond_value = 'X'.
          ls_sales_conditions_inx-cond_type  = 'PR01'.
          APPEND ls_sales_conditions_inx TO lt_sales_conditions_inx.

          IF ls_vbap-netwr1 IS NOT INITIAL.
            CLEAR ls_sales_conditions_in.
            ls_sales_conditions_in-itm_number  = ls_vbap-posnr.    "行项目
            ls_sales_conditions_in-currency    = ls_vbap-waerk.    "货币
            ls_sales_conditions_in-cond_value  = ls_vbap-netwr1.   "折扣
            ls_sales_conditions_in-cond_type   = 'RB00'.           "类型
            APPEND ls_sales_conditions_in TO lt_sales_conditions_in.
            CLEAR ls_sales_conditions_inx.
            ls_sales_conditions_inx-itm_number = ls_vbap-posnr.
            ls_sales_conditions_inx-currency   = 'X'.
            ls_sales_conditions_inx-cond_value = 'X'.
            ls_sales_conditions_inx-cond_type  = 'RB00'.
            APPEND ls_sales_conditions_inx TO lt_sales_conditions_inx.
          ENDIF.
*          CLEAR ls_sales_conditions_in.
*          ls_sales_conditions_in-itm_number  = ls_vbap-posnr.    "行项目
*          ls_sales_conditions_in-currency    = ls_vbap-waerk.    "货币
*          ls_sales_conditions_in-cond_value  = ls_vbap-netwr2.   "运费
*          ls_sales_conditions_in-cond_type   = 'HD00'.           "类型
*          APPEND ls_sales_conditions_in TO lt_sales_conditions_in.
*          CLEAR ls_sales_conditions_inx.
*          ls_sales_conditions_inx-itm_number = ls_vbap-posnr.
*          ls_sales_conditions_inx-currency   = 'X'.
*          ls_sales_conditions_inx-cond_value = 'X'.
*          ls_sales_conditions_inx-cond_type  = 'HD00'.
*          APPEND ls_sales_conditions_inx TO lt_sales_conditions_inx.

        ENDIF.

        CLEAR ls_sales_text.
        ls_sales_text-text_id = '0001'.
        ls_sales_text-langu = sy-langu.
        ls_sales_text-itm_number = ls_vbap-posnr.
        ls_sales_text-text_line = ls_vbap-text01.
        APPEND ls_sales_text TO lt_sales_text.
        CLEAR ls_sales_text.
        ls_sales_text-text_id = '0002'.
        ls_sales_text-langu = sy-langu.
        ls_sales_text-itm_number = ls_vbap-posnr.
        ls_sales_text-text_line = ls_vbap-text02.
        APPEND ls_sales_text TO lt_sales_text.

        "行项目exten
        CLEAR: ls_vbap_ex,ls_vbapx_ex.
        ls_vbap_ex-posnr = ls_vbap-posnr.
        ls_vbap_ex-zwlgs = ls_vbap-zwlgs.
        ls_vbap_ex-zkddh = ls_vbap-zkddh.
        ls_vbap_ex-zcpxh = ls_vbap-zcpxh.
        ls_extension-structure = 'BAPE_VBAP'.
        ls_extension+30 = ls_vbap_ex.
        APPEND ls_extension TO lt_extension.
        CLEAR ls_extension.
        ls_vbapx_ex-posnr = ls_vbap-posnr.
        ls_vbapx_ex-zwlgs = abap_true.
        ls_vbapx_ex-zkddh = abap_true.
        ls_vbapx_ex-zcpxh = abap_true.
        ls_extension-structure = 'BAPE_VBAPX'.
        ls_extension+30 = ls_vbapx_ex.
        APPEND ls_extension TO lt_extension.
        CLEAR ls_extension.
      ENDLOOP.

      CLEAR lv_salesdocument_ex.
      CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'
        EXPORTING
          salesdocument        = lv_salesdocument
          sales_header_in      = ls_order_header_in
          sales_header_inx     = ls_order_header_inx
        IMPORTING
          salesdocument_ex     = lv_salesdocument_ex
        TABLES
          return               = lt_return
          sales_items_in       = lt_sales_items_in
          sales_items_inx      = lt_sales_items_inx
          sales_schedules_in   = lt_sales_schedules_in
          sales_schedules_inx  = lt_sales_schedules_inx
          extensionin          = lt_extension
          sales_conditions_in  = lt_sales_conditions_in
          sales_conditions_inx = lt_sales_conditions_inx
          sales_partners       = lt_sales_partners
          sales_text           = lt_sales_text.

      LOOP AT lt_return INTO ls_return WHERE type = 'E'.
        CLEAR ls_msg.
        ls_msg-message = ls_return-message.
        ls_msg-type = 'E'.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        ls_ztsd003-fail_key = 'X'.

      ENDLOOP.
      IF sy-subrc <> 0.
        CLEAR ls_msg.
        ls_msg-message = ls_vbak-bstnk && '成功创建订单' && lv_salesdocument_ex.
        ls_msg-type = 'S'.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'S' ls_msg-message.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.

        ls_ztsd003-vbeln = lv_salesdocument_ex.
      ENDIF.

      MODIFY ztsd_003 FROM ls_ztsd003.
      IF sy-subrc = 0.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.

    ENDLOOP.
  ENDIF.   " CONFIG = '10'

*********************************************************************
  "修改销售订单
*********************************************************************
  IF i_config = '20'.

    LOOP AT i_vbak_tab INTO ls_vbak.

      READ TABLE o_msg INTO ls_msg WITH KEY bstnk = ls_vbak-bstnk.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      "若无错误则可开始订单修改
      "抬头数据

      REFRESH lt_sales_text.
      IF ls_vbak-text1 IS NOT INITIAL.
        CLEAR ls_sales_text.
        ls_sales_text-doc_number = ls_vbak-vbeln.
        ls_sales_text-text_id = '0001'.
        ls_sales_text-langu = sy-langu.
        ls_sales_text-text_line = ls_vbak-text1.
        ls_sales_text-function = '004'.
        APPEND ls_sales_text TO lt_sales_text.
      ENDIF.

      CLEAR lv_salesdocument.
      lv_salesdocument = ls_vbak-vbeln.

      CLEAR: ls_order_header_in ,ls_order_header_inx.
      IF ls_vbak-bname  IS NOT INITIAL.
        ls_order_header_in_c-name       = ls_vbak-bname.        "联系人
        ls_order_header_inx_c-name       = 'X'.
      ENDIF.
      IF ls_vbak-telf1 IS NOT INITIAL.
        ls_order_header_in_c-telephone  = ls_vbak-telf1.        "联系电话
        ls_order_header_inx_c-telephone  = 'X'.
      ENDIF.

      ls_order_header_in_c-purch_no_c = ls_vbak-bstnk.
      ls_order_header_inx_c-purch_no_c = 'X'.

      ls_order_header_inx_c-updateflag = 'U'.

      "角色
*        REFRESH lt_sales_partners.
*        CLEAR ls_sales_partners.
*        ls_sales_partners-partn_role = 'WE'.
*        ls_sales_partners-partn_numb = ls_vbak-kunnr. "送达方
*        APPEND ls_sales_partners TO lt_sales_partners.
*        CLEAR ls_sales_partners.
*        ls_sales_partners-partn_role = 'AG'.
*        ls_sales_partners-partn_numb = ls_vbak-kunnr. "售达方
*        APPEND ls_sales_partners TO lt_sales_partners.
*        CLEAR ls_sales_partners.
*        ls_sales_partners-partn_role = 'RE'.
*        ls_sales_partners-partn_numb = ls_vbak-kunnr. "售达方
*        APPEND ls_sales_partners TO lt_sales_partners.
*        CLEAR ls_sales_partners.
*        ls_sales_partners-partn_role = 'RG'.
*        ls_sales_partners-partn_numb = ls_vbak-kunnr. "售达方
*        APPEND ls_sales_partners TO lt_sales_partners.
      "抬头extension
      CLEAR: ls_vbak_ex,ls_vbakx_ex.
      ls_vbak_ex-zxfzid = ls_vbak-zxfzid.
      ls_vbak_ex-zywy = ls_vbak-zywy.
      ls_vbak_ex-zshrq = ls_vbak-zshrq.
      ls_vbak_ex-zshr = ls_vbak-zshr.
      ls_vbak_ex-zshcllx = ls_vbak-zshcllx.
      ls_vbak_ex-zdz = ls_vbak-zdz.
      ls_vbak_ex-zgj = ls_vbak-zgj.
      ls_vbak_ex-zsheng = ls_vbak-zsheng.
      ls_vbak_ex-zshi = ls_vbak-zshi.
      ls_vbak_ex-zqx = ls_vbak-zqx.
      ls_vbak_ex-zxsdq = ls_vbak-zxsdq.
      ls_vbak_ex-zkhdj = ls_vbak-zkhdj.
      ls_vbak_ex-zfkfs = ls_vbak-zfkfs.
      ls_vbak_ex-zhth = ls_vbak-zhth.
      ls_vbak_ex-zwbxtbs = ls_vbak-zwbxtbs.
      ls_vbak_ex-zcjsj = ls_vbak-zcjsj.
      ls_vbak_ex-zfksj = ls_vbak-zfksj.
      ls_extension_u-structure = 'BAPE_VBAK'.
      ls_extension_u+30 = ls_vbak_ex.
      APPEND ls_extension_u TO lt_extension_u.
      CLEAR ls_extension_u.
      ls_vbakx_ex-zxfzid  = abap_true.
      ls_vbakx_ex-zywy    = abap_true.
      ls_vbakx_ex-zshrq   = abap_true.
      ls_vbakx_ex-zshr    = abap_true.
      ls_vbakx_ex-zshcllx = abap_true.
      ls_vbakx_ex-zdz     = abap_true.
      ls_vbakx_ex-zgj     = abap_true.
      ls_vbakx_ex-zsheng  = abap_true.
      ls_vbakx_ex-zshi    = abap_true.
      ls_vbakx_ex-zqx     = abap_true.
      ls_vbakx_ex-zxsdq   = abap_true.
      ls_vbakx_ex-zkhdj   = abap_true.
      ls_vbakx_ex-zfkfs   = abap_true.
      ls_vbakx_ex-zhth    = abap_true.
      ls_vbakx_ex-zwbxtbs = abap_true.
      ls_vbakx_ex-zcjsj   = abap_true.
      ls_vbakx_ex-zfksj   = abap_true.
      ls_extensionx_u-structure = 'BAPE_VBAKX'.
      ls_extensionx_u+30 = ls_vbakx_ex.
      APPEND ls_extensionx_u TO lt_extensionx_u.
      CLEAR ls_extensionx_u.


      "行数据
      REFRESH: lt_sales_items_in ,lt_sales_items_inx,
      lt_sales_schedules_in ,lt_sales_schedules_inx,
      lt_sales_conditions_in ,lt_sales_conditions_inx.

      LOOP AT i_vbap_tab INTO ls_vbap WHERE bstnk = ls_vbak-bstnk.

        CLEAR ls_sales_items_in.
        ls_sales_items_in-itm_number   = ls_vbap-posnr.   "行项目
        ls_sales_items_in-material     = ls_vbap-matnr.   "物料编码
        ls_sales_items_in-plant        = ls_vbap-werks.   "工厂
        ls_sales_items_in-store_loc    = ls_vbap-lgort.   "库存地点
        ls_sales_items_in-reason_rej   = ls_vbap-abgru.   "拒绝原因

        APPEND ls_sales_items_in TO lt_sales_items_in.

        CLEAR ls_sales_items_inx.
        ls_sales_items_inx-updateflag   = 'U'.
        ls_sales_items_inx-itm_number   = ls_vbap-posnr.
        ls_sales_items_inx-material     = 'X'.
        "ls_sales_items_inx-target_qty   = 'X'.
        ls_sales_items_inx-plant        = 'X'.
        ls_sales_items_inx-store_loc    = 'X'.
        ls_sales_items_inx-reason_rej   = 'X'.
        "ls_sales_items_inx-item_categ   = 'X'.
        APPEND ls_sales_items_inx TO lt_sales_items_inx.

        CLEAR ls_sales_schedules_in.
        ls_sales_schedules_in-itm_number = ls_vbap-posnr.
        ls_sales_schedules_in-sched_line = 1.
        ls_sales_schedules_in-req_qty    = ls_vbap-kwmeng.    "数量
        APPEND ls_sales_schedules_in TO lt_sales_schedules_in.

        CLEAR ls_sales_schedules_inx.
        ls_sales_schedules_inx-updateflag    = 'U'.
        ls_sales_schedules_inx-sched_line    = 1.
        ls_sales_schedules_inx-itm_number    = ls_vbap-posnr.
        ls_sales_schedules_inx-req_qty       = 'X'.    "数量
        APPEND ls_sales_schedules_inx TO lt_sales_schedules_inx.

        IF ls_vbap-kbetr IS NOT INITIAL.
          CLEAR ls_sales_conditions_in.
          ls_sales_conditions_in-itm_number  = ls_vbap-posnr.   "行项目
          ls_sales_conditions_in-currency    = ls_vbap-waerk.   "货币
          ls_sales_conditions_in-cond_count  = '01'.
          ls_sales_conditions_in-cond_value  = ls_vbap-kbetr.   "净值
          ls_sales_conditions_in-cond_type   = 'PR01'.          "类型
          APPEND ls_sales_conditions_in TO lt_sales_conditions_in.
          CLEAR ls_sales_conditions_inx.
          ls_sales_conditions_inx-updateflag = 'U'.
          ls_sales_conditions_inx-itm_number = ls_vbap-posnr.
          ls_sales_conditions_inx-cond_count = '01'.
          ls_sales_conditions_inx-currency   = 'X'.
          ls_sales_conditions_inx-cond_value = 'X'.
          ls_sales_conditions_inx-cond_type  = 'PR01'.
          APPEND ls_sales_conditions_inx TO lt_sales_conditions_inx.
        ENDIF.
        IF ls_vbap-netwr1 IS NOT INITIAL.
          CLEAR ls_sales_conditions_in.
          ls_sales_conditions_in-itm_number  = ls_vbap-posnr.    "行项目
          ls_sales_conditions_in-cond_count  = '02'.
          ls_sales_conditions_in-currency    = ls_vbap-waerk.    "货币
          ls_sales_conditions_in-cond_value  = ls_vbap-netwr1.   "折扣
          ls_sales_conditions_in-cond_type   = 'RB00'.           "类型
          APPEND ls_sales_conditions_in TO lt_sales_conditions_in.
          CLEAR ls_sales_conditions_inx.
          ls_sales_conditions_inx-updateflag = 'U'.
          ls_sales_conditions_inx-itm_number = ls_vbap-posnr.
          ls_sales_conditions_inx-cond_count = '02'.
          ls_sales_conditions_inx-currency   = 'X'.
          ls_sales_conditions_inx-cond_value = 'X'.
          ls_sales_conditions_inx-cond_type  = 'RB00'.
          APPEND ls_sales_conditions_inx TO lt_sales_conditions_inx.
        ENDIF.
*        IF ls_vbap-netwr2 IS NOT INITIAL.
*          CLEAR ls_sales_conditions_in.
*          ls_sales_conditions_in-itm_number  = ls_vbap-posnr.    "行项目
*          ls_sales_conditions_in-cond_count  = '01'.
*          ls_sales_conditions_in-currency    = ls_vbap-waerk.    "货币
*          ls_sales_conditions_in-cond_value  = ls_vbap-netwr2.   "运费
*          ls_sales_conditions_in-cond_type   = 'HD00'.           "类型
*          APPEND ls_sales_conditions_in TO lt_sales_conditions_in.
*          CLEAR ls_sales_conditions_inx.
*          ls_sales_conditions_inx-updateflag = 'U'.
*          ls_sales_conditions_inx-itm_number = ls_vbap-posnr.
*          ls_sales_conditions_inx-cond_count = '01'.
*          ls_sales_conditions_inx-currency   = 'X'.
*          ls_sales_conditions_inx-cond_value = 'X'.
*          ls_sales_conditions_inx-cond_type  = 'HD00'.
*          APPEND ls_sales_conditions_inx TO lt_sales_conditions_inx.
*        ENDIF.

        IF ls_vbap-text01 IS NOT INITIAL.
          CLEAR ls_sales_text.
          ls_sales_text-text_id = '0001'.
          ls_sales_text-doc_number = lv_salesdocument.
          ls_sales_text-langu = sy-langu.
          ls_sales_text-itm_number = ls_vbap-posnr.
          ls_sales_text-text_line = ls_vbap-text01.
          ls_sales_text-function = '004'.
          APPEND ls_sales_text TO lt_sales_text.
        ENDIF.
        IF ls_vbap-text02 IS NOT INITIAL.
          CLEAR ls_sales_text.
          ls_sales_text-text_id = '0002'.
          ls_sales_text-doc_number = lv_salesdocument.
          ls_sales_text-langu = sy-langu.
          ls_sales_text-itm_number = ls_vbap-posnr.
          ls_sales_text-text_line = ls_vbap-text02.
          ls_sales_text-function = '004'.
          APPEND ls_sales_text TO lt_sales_text.
        ENDIF.

                "行项目exten
        CLEAR: ls_vbap_ex,ls_vbapx_ex.
        ls_vbap_ex-posnr = ls_vbap-posnr.
        ls_vbap_ex-zwlgs = ls_vbap-zwlgs.
        ls_vbap_ex-zkddh = ls_vbap-zkddh.
        ls_vbap_ex-zcpxh = ls_vbap-zcpxh.
        ls_extension_u-structure = 'BAPE_VBAP'.
        ls_extension_u+30 = ls_vbap_ex.
        APPEND ls_extension_u TO lt_extension_u.
        CLEAR ls_extension_u.
        ls_vbapx_ex-posnr = ls_vbap-posnr.
        ls_vbapx_ex-zwlgs = abap_true.
        ls_vbapx_ex-zkddh = abap_true.
        ls_vbapx_ex-zcpxh = abap_true.
        ls_extensionx_u-structure = 'BAPE_VBAPX'.
        ls_extensionx_u+30 = ls_vbapx_ex.
        APPEND ls_extensionx_u TO lt_extensionx_u.
        CLEAR ls_extensionx_u.
      ENDLOOP.

      CLEAR ls_logic_switch.
      ls_logic_switch-cond_handl = 'X'.
      CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
        EXPORTING
          salesdocument    = lv_salesdocument
          order_header_in  = ls_order_header_in_c
          order_header_inx = ls_order_header_inx_c
          logic_switch     = ls_logic_switch
        TABLES
          return           = lt_return
          order_item_in    = lt_sales_items_in
          order_item_inx   = lt_sales_items_inx
          "partners         = lt_sales_partners
          schedule_lines   = lt_sales_schedules_in
          schedule_linesx  = lt_sales_schedules_inx
          conditions_in    = lt_sales_conditions_in
          conditions_inx   = lt_sales_conditions_inx
          order_text       = lt_sales_text.


      LOOP AT lt_return INTO ls_return WHERE type = 'E'.
        CLEAR ls_msg.
        ls_msg-message = ls_return-message.
        ls_msg-type = 'E'.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      ENDLOOP.
      IF sy-subrc <> 0.
        CLEAR ls_msg.
        ls_msg-message = '订单' && ls_vbak-vbeln && '修改成功'.
        ls_msg-type = 'S'.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'S' ls_msg-message.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.

    ENDLOOP.

  ENDIF.


  /afl/save.   "记录日志
ENDFUNCTION.
