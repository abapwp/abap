FUNCTION zfm_sd019.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(I_CONFIG) TYPE  ZE_SD019_CON
*"     VALUE(I_VBELN) TYPE  VBELN
*"     VALUE(I_BSTNK) TYPE  ZESD019_BSTNK
*"     VALUE(I_DATE) TYPE  SY-DATUM OPTIONAL
*"  EXPORTING
*"     VALUE(O_MSG) TYPE  ZTTSD019_A
*"----------------------------------------------------------------------

  DATA lw_msg TYPE zssd019_a .

"  订单 类型 ZTA  B端销售订单，  ZTA1 C端销售订单  vbak-auart   pstyv, 类别  posar 类型  vbap

  IF i_date IS INITIAL.
    i_date = sy-datum .
  ENDIF.


  CHECK o_msg[] IS INITIAL .

  IF i_config EQ '10' .

    SELECT vbeln,posnr,matnr,lgort,werks,kwmeng,pstyv,posar
      INTO TABLE @DATA(lt_vbap)
      FROM vbap
      WHERE vbeln = @i_vbeln .

    IF lt_vbap is not initial.

      select mard~matnr,
             mard~werks,
             mard~lgort,
             mard~exppg,
             mard~lgpbe,
             mard~labst
        into table @data(lt_mard)
        from mard
        inner join marc on mard~werks = marc~werks and marc~xchar ne 'X'
        FOR ALL ENTRIES IN @lt_vbap
        where mard~matnr = @lt_vbap-matnr
          and mard~werks = @lt_vbap-werks
          and mard~lgort = @lt_vbap-lgort
          and mard~labst gt 0 .

      IF lines( lt_vbap ) ne lines( lt_mard ).
        clear lw_msg .
        lw_msg-type = 'E' .
        lw_msg-message = lw_msg-message && '该销售订单涉及物料中，存在在非限制库存中没有数量的物料；' .
        lw_msg-bstnk = i_bstnk .
        lw_msg-vbeln = i_vbeln .
        append lw_msg to o_msg .
        exit .
      ENDIF.


    else.

      clear lw_msg .
        lw_msg-type = 'E' .
        lw_msg-message = lw_msg-message && '该销售订单不存在；' .
        lw_msg-bstnk = i_bstnk .
        lw_msg-vbeln = i_vbeln .
        append lw_msg to o_msg .
        exit .
    ENDIF.

    check o_msg is initial .

    select single auart into @data(lv_auart)
      from vbak
      where vbeln = @i_vbeln .

   data lv_num type i .

    IF lv_auart eq 'ZTA'. " B 端销售订单
      " 校验并修改 E库存锁定 前提
      clear lv_num .
      loop at lt_vbap into data(lw_vbap) where pstyv eq 'CN' .
       lv_num = lv_num + 1 .
      endloop .
      IF lines( lt_vbap ) ne lv_num .
        " 修改 需求类别 为 CN

      ENDIF.

   ELSEIF lv_auart eq 'ZTA1 '. " C端销售订单
     clear lv_num .
      loop at lt_vbap into data(lw_vbap1) where pstyv eq 'CN' and posar = 'KEV'.
       lv_num = lv_num + 1 .
      endloop .
      IF lines( lt_vbap ) ne lv_num .
        " 修改 需求类别 为 CN ,类型改为  KEV
      ENDIF.

   ENDIF.

  ENDIF.


  IF i_config = '20'.

    SELECT vbeln,posnr,matnr,lgort,werks,kwmeng,pstyv,posar
      INTO TABLE @DATA(lt_vbap1)
      FROM vbap
      WHERE vbeln = @i_vbeln .

    IF lt_vbap is not initial.

      select matnr,werks,lgort,sobkz,charg,kalab,vbeln,posnr
        into table @data(lt_mska)
        from mska
        for ALL ENTRIES IN @lt_vbap1
        where vbeln = @lt_vbap1-vbeln and posnr = @lt_vbap1-posnr
        and matnr = @lt_vbap1-matnr and werks = @lt_vbap1-werks
        and lgort = @lt_vbap1-lgort and kalab gt 0 .

      IF lines( lt_vbap ) ne lines( lt_mska ).
        clear lw_msg .
        lw_msg-type = 'E' .
        lw_msg-message = lw_msg-message && '该销售订单存在在E库存中没有数量的条目；' .
        lw_msg-bstnk = i_bstnk .
        lw_msg-vbeln = i_vbeln .
        append lw_msg to o_msg .
        exit .
      ENDIF.

    else.
      clear lw_msg .
        lw_msg-type = 'E' .
        lw_msg-message = lw_msg-message && '该销售订单不存在；' .
        lw_msg-bstnk = i_bstnk .
        lw_msg-vbeln = i_vbeln .
        append lw_msg to o_msg .
        exit .
    ENDIF.

    check o_msg is initial .
    select single auart into @data(lv_auart1)
      from vbak
      where vbeln = @i_vbeln .

    IF lv_auart1 eq 'ZAT '.
      " E 库存释放  B 销售订单

      " 把B端销售订单需求类别改为CP

    elseif lv_auart1 eq 'ZAT1' .
      " E 库存释放  C 销售订单
    ENDIF.

  ENDIF.


ENDFUNCTION.
