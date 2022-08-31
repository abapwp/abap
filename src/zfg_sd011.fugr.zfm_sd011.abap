FUNCTION zfm_sd011.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(I_VBELN) TYPE  VBELN
*"     VALUE(I_BUDAT) TYPE  BUDAT OPTIONAL
*"     VALUE(I_LIKP_TAB) TYPE  ZTTSD011_LIKP
*"     VALUE(I_LIPS_TAB) TYPE  ZTTSD011_LIPS
*"     VALUE(I_SERI_TAB) TYPE  ZTTSD011_SERI
*"  TABLES
*"      O_MSG STRUCTURE  ZSSD011_D OPTIONAL
*"----------------------------------------------------------------------

  /afl/log_init.   "初始化日志

  DATA: ls_likp TYPE zssd011_a.
  DATA: ls_lips TYPE zssd011_b.
  DATA: ls_seri TYPE zssd011_c.
  DATA: ls_msg  TYPE zssd011_d.

  "数据校验
  LOOP AT i_likp_tab INTO ls_likp.
    IF ls_likp-bstnk IS INITIAL.
      CLEAR ls_msg.
      ls_msg-type = 'E'.
      ls_msg-message = '外围系统唯一流水号未给出！'.
      APPEND ls_msg TO o_msg.
      /afl/set_status 'E' ls_msg-message.    "更新日志
      CONTINUE.
    ENDIF.

    LOOP AT I_lips_tab INTO ls_lips WHERE bstnk = ls_likp-bstnk AND vbeln = ls_likp-vbeln.
      IF ls_lips-bstnk IS INITIAL OR ls_lips-vbeln IS INITIAL OR ls_lips-posnr IS INITIAL OR
         ls_lips-matnr IS INITIAL OR ls_lips-kwmeng IS INITIAL OR ls_lips-meng IS INITIAL OR
         ls_lips-vrkme IS INITIAL OR ls_lips-werks IS INITIAL OR ls_lips-werks IS INITIAL OR
         ls_lips-lgort IS INITIAL.
        CLEAR ls_msg.
        ls_msg-message = '交货单' && i_vbeln && '的行项目数据存在缺失！'.
        ls_msg-type = 'E'.
        ls_msg-vbeln = i_vbeln.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
        CONTINUE.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR ls_msg.
      ls_msg-message = '交货单' && i_vbeln && '没有行项目数据！'.
      ls_msg-type = 'E'.
      ls_msg-vbeln = i_vbeln.
      APPEND ls_msg TO o_msg.
      /afl/set_status 'E' ls_msg-message.
      CONTINUE.
    ENDIF.


    DATA: ls_vbkok    TYPE vbkok,
          lv_delivery TYPE likp-vbeln,
          ls_vbpok    TYPE vbpok,
          lt_vbpok    TYPE TABLE OF vbpok,
          ls_prot     TYPE prott,
          lt_prot     TYPE TABLE OF prott.

    CLEAR ls_vbkok.
    ls_vbkok = VALUE #( vbeln_vl  = I_vbeln
                        wadat_ist = i_budat
                        wabuc     = 'X' ).
    CLEAR lv_delivery.
    lv_delivery = I_vbeln.
    CLEAR ls_vbpok.
    ls_vbpok = VALUE #( vbeln_vl = ls_lips-vbeln
                        posnr_vl = ls_lips-posnr
                        vbeln    = ls_lips-vbeln
                        posnn    = ls_lips-posnr
                        werks    = ls_lips-werks
                        lgort    = ls_lips-lgort
                        matnr    = ls_lips-matnr
                        lfimg    = ls_lips-kwmeng
                        pikmg    = ls_lips-meng ).
    APPEND ls_vbpok TO lt_vbpok.

    "拣配并过账
    CALL FUNCTION 'WS_DELIVERY_UPDATE'
      EXPORTING
        vbkok_wa       = ls_vbkok
        delivery       = lv_delivery
        update_picking = 'X'
      TABLES
        vbpok_tab      = lt_vbpok
        prot           = lt_prot.
DATA: lv_msgtx TYPE CHAR200.
    LOOP AT lt_prot INTO ls_prot WHERE msgty = 'E'.
      CLEAR lv_msgtx.
      CONDENSE ls_prot-msgv1 NO-GAPS.
      CONDENSE ls_prot-msgv2 NO-GAPS.
      CONDENSE ls_prot-msgv3 NO-GAPS.
      CONDENSE ls_prot-msgv4 NO-GAPS.
      CALL FUNCTION 'MESSAGE_TEXT_BUILD'
        EXPORTING
        msgid               = ls_prot-msgid
        msgnr               = ls_prot-msgno
        msgv1               = ls_prot-msgv1
        msgv2               = ls_prot-msgv2
        msgv3               = ls_prot-msgv3
        msgv4               = ls_prot-msgv4
      IMPORTING
        MESSAGE_TEXT_OUTPUT = lv_msgtx.
      CLEAR ls_msg.
      ls_msg-message = '交货单' && i_vbeln && '过账失败！' && lv_msgtx.
      ls_msg-type = 'E'.
      ls_msg-vbeln = i_vbeln.
      APPEND ls_msg TO o_msg.
      /afl/set_status 'E' ls_msg-message.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      /afl/set_status 'E' ls_msg-message.
    ENDLOOP.
    if sy-subrc <> 0.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

      SELECT MAX( vbeln )
      INTO @DATA(lv_mblnr)
      FROM vbfa
      WHERE vbelv = @I_vbeln
      AND vbtyp_n = 'R'.
      IF sy-subrc = 0.
        CLEAR ls_msg.
        ls_msg-message = '交货单' && i_vbeln && '过账成功！生成凭证' && lv_mblnr.
        ls_msg-type = 'S'.
        ls_msg-vbeln = i_vbeln.
        ls_msg-mblnr = lv_mblnr.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'S' ls_msg-message.
      ELSE.
        CLEAR ls_msg.
        ls_msg-message = '交货单' && i_vbeln && '过账失败，凭证未生成！' .
        ls_msg-type = 'E'.
        ls_msg-vbeln = i_vbeln.
        APPEND ls_msg TO o_msg.
        /afl/set_status 'E' ls_msg-message.
      ENDIF.
    ENDIF.
  ENDLOOP.
  /afl/save.   "记录日志
ENDFUNCTION.
