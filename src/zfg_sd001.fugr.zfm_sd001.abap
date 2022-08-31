FUNCTION zfm_sd001.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(FD_DATA) TYPE  STRING OPTIONAL
*"     VALUE(FS_SDJFH) TYPE  ZSSD001 OPTIONAL
*"  EXPORTING
*"     VALUE(STATUS) TYPE  STRING
*"     VALUE(MSG) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: lv_businesspartner TYPE  bapibus1006_head-bpartner.
  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2.
  DATA: zt_basic_add TYPE TABLE OF zssd001_basic WITH HEADER LINE,
        zt_basic_upd TYPE TABLE OF zssd001_basic WITH HEADER LINE.
  DATA: text(220) TYPE c VALUE '该数据已经导入，请勿重复操作'.
  DATA: sjonstr TYPE string.
  DATA:ls_data TYPE zssd001.
  DATA:es_data TYPE zssd001.
  DATA: zt_basic_data TYPE TABLE OF zssd001_basic WITH HEADER LINE,
        zt_fi_data    TYPE TABLE OF zssd001_fi WITH HEADER LINE,
        zt_sales_data TYPE TABLE OF zssd001_sales WITH HEADER LINE,
        zt_ukm_data   TYPE TABLE OF zssd001_ukm WITH HEADER LINE.


  IF fs_sdjfh IS NOT INITIAL.
    "反序列json解析
    /ui2/cl_json=>serialize( EXPORTING data = fs_sdjfh
                             RECEIVING  r_json = sjonstr ).
    fd_data = sjonstr.
  ENDIF.


  "反序列json解析
  /ui2/cl_json=>deserialize( EXPORTING json = fd_data
                              CHANGING  data = ls_data ).

  IF ls_data IS INITIAL.
    status = 'E'.
    msg = '解析JSON字段出错，请检查字段结构'.
    RETURN.
  ENDIF.
  zt_basic_data[] = ls_data-zt_basic_data.
  zt_fi_data[]    = ls_data-zt_fi_data.
  zt_sales_data[] = ls_data-zt_sales_data.
  zt_ukm_data[]   = ls_data-zt_ukm_data.
  DATA(zbasic)    = ls_data-zbasic.
  DATA(zfi)       = ls_data-zfi   .
  DATA(zsales)    = ls_data-zsales.
  DATA(zukm)      = ls_data-zukm  .

  IF zbasic = 'X'.
*********************拆分数据*************************
    LOOP AT zt_basic_data.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = zt_basic_data-kunnr
        IMPORTING
          output = zt_basic_data-kunnr.
      DATA:lv_langu TYPE sy-langu.
      CLEAR:lv_langu.
      CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
        EXPORTING
          input  = zt_basic_data-spras
        IMPORTING
          output = lv_langu.
      zt_basic_data-spras = lv_langu.

      CASE zt_basic_data-zflag.
        WHEN 'I'.
          MOVE-CORRESPONDING zt_basic_data TO zt_basic_add.
          APPEND zt_basic_add.
        WHEN 'U' OR 'D'.
          MOVE-CORRESPONDING zt_basic_data TO zt_basic_upd.
          APPEND zt_basic_upd.
        WHEN OTHERS.
      ENDCASE.
      MODIFY zt_basic_data .
    ENDLOOP.
    SORT zt_basic_add BY kunnr.
    SORT zt_basic_upd BY kunnr.

*************************基本数据新增*****************************
    LOOP AT zt_basic_add.

      IF zt_basic_add-ktokd = 'Z001' OR zt_basic_add-ktokd = 'Z004'.

        lv_businesspartner = zt_basic_add-kunnr.
        CALL FUNCTION 'BAPI_BUPA_EXISTENCE_CHECK'
          EXPORTING
            businesspartner = lv_businesspartner
          TABLES
            return          = lt_return.

        IF  lt_return[] IS NOT INITIAL. "不存在  添加
          PERFORM frm_create USING zt_basic_add.
        ELSE.                           "存在报错
          zt_basic_add-ztype = 'S'.
          zt_basic_add-zmessage = '客户' && lv_businesspartner && '已存在'.
        ENDIF.

      ELSE.
        PERFORM frm_create USING zt_basic_add .
      ENDIF.

      MODIFY zt_basic_add.

    ENDLOOP.

*************************基本数据修改/删除*****************************

    LOOP AT zt_basic_upd.

      PERFORM frm_modify USING zt_basic_upd.

      MODIFY zt_basic_upd.

    ENDLOOP.

*************************合并基本数据*****************************
    LOOP AT zt_basic_data.

      IF zt_basic_data-zflag = 'I'.
        CLEAR zt_basic_add.
        READ TABLE zt_basic_add WITH KEY kunnr = zt_basic_data-kunnr BINARY SEARCH.
        IF sy-subrc = 0 .
          zt_basic_data-ztype = zt_basic_add-ztype.
          zt_basic_data-zmessage = zt_basic_add-zmessage.
        ELSEIF zt_basic_data-kunnr IS INITIAL.
          READ TABLE zt_basic_add INDEX 1.
          IF sy-subrc = 0.
            zt_basic_data-ztype = zt_basic_add-ztype.
            zt_basic_data-zmessage = zt_basic_add-zmessage.
            zt_basic_data-kunnr = zt_basic_add-kunnr.
          ENDIF.
        ENDIF.
      ELSE.
        READ TABLE zt_basic_upd WITH KEY kunnr = zt_basic_data-kunnr BINARY SEARCH.
        IF sy-subrc = 0 .
          zt_basic_data-ztype = zt_basic_upd-ztype.
          zt_basic_data-zmessage = zt_basic_upd-zmessage.
        ENDIF.
      ENDIF.
      MODIFY zt_basic_data.
    ENDLOOP.

  ENDIF.

************************************扩充/冻结 财务数据***************************************
  IF zfi = 'X'.
*&---------------------------------------------------------------------*
    DATA: lt_kna1 TYPE TABLE OF kna1 WITH HEADER LINE.
    IF zt_fi_data[] IS NOT INITIAL.
      SELECT  kunnr
        INTO CORRESPONDING FIELDS OF TABLE lt_kna1
        FROM kna1
        FOR ALL ENTRIES IN zt_fi_data
        WHERE kunnr = zt_fi_data-kunnr.
      SORT lt_kna1 BY kunnr.
      DELETE ADJACENT DUPLICATES FROM lt_kna1 COMPARING kunnr.
    ENDIF.

    LOOP AT zt_fi_data WHERE zmessage NE '该数据已经导入，请勿重复操作'.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = zt_fi_data-kunnr
        IMPORTING
          output = zt_fi_data-kunnr.

      CLEAR: lt_kna1.
      READ TABLE lt_kna1 WITH KEY kunnr = zt_fi_data-kunnr.
      IF sy-subrc = 0.
        PERFORM frm_create_fi USING zt_fi_data.
      ELSE.
        zt_fi_data-ztype = 'E'.
        zt_fi_data-zmessage = '该客户不存在'.
      ENDIF.

      MODIFY zt_fi_data.
    ENDLOOP.

  ENDIF.

***************************************扩充/冻结 销售数据****************************************
  IF zsales = 'X'.
*&---------------------------------------------------------------------*
    CLEAR: zt_sales_data.
    IF zt_sales_data[] IS NOT INITIAL.
      SELECT  kunnr
        INTO CORRESPONDING FIELDS OF TABLE lt_kna1
        FROM kna1
        FOR ALL ENTRIES IN zt_sales_data
        WHERE kunnr = zt_sales_data-kunnr.
      SORT lt_kna1 BY kunnr.
      DELETE ADJACENT DUPLICATES FROM lt_kna1 COMPARING kunnr.
    ENDIF.

    LOOP AT zt_sales_data WHERE zmessage NE '该数据已经导入，请勿重复操作'.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = zt_sales_data-kunnr
        IMPORTING
          output = zt_sales_data-kunnr.

      CLEAR: lt_kna1.
      READ TABLE lt_kna1 WITH KEY kunnr = zt_sales_data-kunnr.
      IF sy-subrc = 0.
        PERFORM frm_create_sales USING zt_sales_data lt_kna1.
      ELSE.
        zt_sales_data-ztype = 'E'.
        zt_sales_data-zmessage = '该客户不存在'.
      ENDIF.

      MODIFY zt_sales_data.
    ENDLOOP.

  ENDIF.

***************************************扩充 信用段****************************************
  IF zukm = 'X'.
    LOOP AT zt_ukm_data  .
      IF zt_ukm_data-credit_sgmnt < 0.
        zt_ukm_data-ztype = 'E'.
        zt_ukm_data-zmessage = '额度不能小于0'.
      ELSE.
        PERFORM frm_create_zukm CHANGING zt_ukm_data.
      ENDIF.
      MODIFY zt_ukm_data.
    ENDLOOP.
  ENDIF.

*************************************存日志表****************************************
  DATA(iv_guid) = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
  IF zbasic = 'X'.
    DATA: gtsd_basic_log TYPE TABLE OF ztsd_basic_log WITH HEADER LINE.
    gtsd_basic_log[] = CORRESPONDING #( zt_basic_data[] ).
    LOOP AT gtsd_basic_log .
      gtsd_basic_log-zguid     = iv_guid .
      gtsd_basic_log-zno_log   = sy-tabix .
      gtsd_basic_log-zdate_log = sy-datum .
      gtsd_basic_log-ztime_log = sy-uzeit .
      gtsd_basic_log-zitype    = 'I' .
      MODIFY gtsd_basic_log.
    ENDLOOP.
    MODIFY ztsd_basic_log FROM TABLE gtsd_basic_log.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ENDIF.

  IF zfi = 'X'.
    DATA: gtsd_fi_log TYPE TABLE OF ztsd_fi_log WITH HEADER LINE.
    gtsd_fi_log[] = CORRESPONDING #( zt_fi_data[] ).
    LOOP AT gtsd_fi_log .
      gtsd_fi_log-zguid     = iv_guid .
      gtsd_fi_log-zno_log   = sy-tabix .
      gtsd_fi_log-zdate_log = sy-datum .
      gtsd_fi_log-ztime_log = sy-uzeit .
      gtsd_fi_log-zitype    = 'I' .
      MODIFY gtsd_fi_log.
    ENDLOOP.
    MODIFY ztsd_fi_log FROM TABLE gtsd_fi_log.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ENDIF.

  IF zsales = 'X'.
    DATA: gtsd_sales_log TYPE TABLE OF ztsd_sales_log WITH HEADER LINE.
    gtsd_sales_log[] = CORRESPONDING #( zt_sales_data[] ).
    LOOP AT gtsd_sales_log .
      gtsd_sales_log-zguid     = iv_guid .
      gtsd_sales_log-zno_log   = sy-tabix .
      gtsd_sales_log-zdate_log = sy-datum .
      gtsd_sales_log-ztime_log = sy-uzeit .
      gtsd_sales_log-zitype    = 'I' .
      MODIFY gtsd_sales_log.
    ENDLOOP.
    MODIFY ztsd_sales_log FROM TABLE gtsd_sales_log.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ENDIF.

  IF zukm = 'X'.
    DATA: gtsd_ukm_log TYPE TABLE OF ztsd_ukm_log WITH HEADER LINE.
    gtsd_ukm_log[] = CORRESPONDING #( zt_ukm_data[] ).
    LOOP AT gtsd_ukm_log .
      gtsd_ukm_log-zguid     = iv_guid .
      gtsd_ukm_log-zno_log   = sy-tabix .
      gtsd_ukm_log-zdate_log = sy-datum .
      gtsd_ukm_log-ztime_log = sy-uzeit .
      gtsd_ukm_log-zitype    = 'I' .
      MODIFY gtsd_ukm_log.
    ENDLOOP.
    MODIFY ztsd_ukm_log FROM TABLE gtsd_ukm_log.
    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ENDIF.

  DATA:lv_error TYPE c.
  DATA:lv_msg TYPE bapi_msg.

  CLEAR:lv_error.
  LOOP AT zt_basic_data WHERE ztype = 'E'.
    IF lv_msg IS NOT INITIAL.
      CONCATENATE lv_msg '|' zt_basic_data-zmessage INTO lv_msg.
    ELSE.
      CONCATENATE lv_msg zt_basic_data-zmessage INTO lv_msg.
    ENDIF.
  ENDLOOP.
  IF sy-subrc NE 0.
    READ TABLE zt_basic_data INDEX 1.
    IF sy-subrc = 0.
      DATA(lv_kunnr) = zt_basic_data-kunnr.
    ENDIF.
  ENDIF.

  LOOP AT zt_fi_data WHERE ztype = 'E'.
    IF lv_msg IS NOT INITIAL.
      CONCATENATE lv_msg '|' zt_fi_data-zmessage INTO lv_msg.
    ELSE.
      CONCATENATE lv_msg zt_fi_data-zmessage INTO lv_msg.
    ENDIF.
  ENDLOOP.

  LOOP AT zt_sales_data WHERE ztype = 'E'.
    IF lv_msg IS NOT INITIAL.
      CONCATENATE lv_msg '|' zt_sales_data-zmessage INTO lv_msg.
    ELSE.
      CONCATENATE lv_msg zt_sales_data-zmessage INTO lv_msg.
    ENDIF.
  ENDLOOP.

  LOOP AT zt_ukm_data WHERE ztype = 'E'.
    IF lv_msg IS NOT INITIAL.
      CONCATENATE lv_msg '|' zt_ukm_data-zmessage INTO lv_msg.
    ELSE.
      CONCATENATE lv_msg zt_ukm_data-zmessage INTO lv_msg.
    ENDIF.
  ENDLOOP.

  es_data-zt_basic_data = zt_basic_data[].
  es_data-zt_fi_data    = zt_fi_data[].
  es_data-zt_sales_data = zt_sales_data[].
  es_data-zt_ukm_data   = zt_ukm_data[].

  es_data-zbasic = ls_data-zbasic.
  es_data-zfi    = ls_data-zfi.
  es_data-zsales = ls_data-zsales.
  es_data-zukm   = ls_data-zukm.
  IF lv_msg IS NOT INITIAL.
    lv_error = 'X'.
    status = 'E'.
    msg = lv_msg.
  ELSE.
    status = 'S'.
    msg = lv_kunnr.
    "json解析
    /ui2/cl_json=>serialize( EXPORTING data = es_data
                             RECEIVING  r_json = msg ).
  ENDIF.

ENDFUNCTION.
