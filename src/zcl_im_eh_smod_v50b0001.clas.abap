class ZCL_IM_EH_SMOD_V50B0001 definition
  public
  final
  create public .

public section.

  interfaces IF_EX_SMOD_V50B0001 .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_EH_SMOD_V50B0001 IMPLEMENTATION.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50I_001.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50I_002.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50I_003.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50I_004.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50I_009.
  endmethod.


  METHOD if_ex_smod_v50b0001~exit_saplv50i_010.

    "外围系统唯一流水号
    READ TABLE extension2 INTO DATA(ls_extension2) WITH KEY param = 'LIKP' field = 'ZBSTNK'.
    IF sy-subrc = 0.
      MOVE ls_extension2-value TO cs_vbkok-zbstnk.
      CLEAR ls_extension2.
    ENDIF.

    "装箱单号
    READ TABLE extension2 INTO ls_extension2 WITH KEY param = 'LIKP' field = 'ZZXDH'.
    IF sy-subrc = 0.
      MOVE ls_extension2-value TO cs_vbkok-zzxdh.
      CLEAR ls_extension2.
    ENDIF.

    "物流公司
    READ TABLE extension2 INTO ls_extension2 WITH KEY param = 'LIKP' field = 'ZWLGS'.
    IF sy-subrc = 0.
      MOVE ls_extension2-value TO cs_vbkok-zwlgs.
      CLEAR ls_extension2.
    ENDIF.

    "快递单号
    READ TABLE extension2 INTO ls_extension2 WITH KEY param = 'LIKP' field = 'ZKDDH'.
    IF sy-subrc = 0.
      MOVE ls_extension2-value TO cs_vbkok-zkddh.
      CLEAR ls_extension2.
    ENDIF.

    "店铺名称/客户名称
    READ TABLE extension2 INTO ls_extension2 WITH KEY param = 'LIKP' field = 'ZDPMC'.
    IF sy-subrc = 0.
      MOVE ls_extension2-value TO cs_vbkok-zdpmc.
      CLEAR ls_extension2.
    ENDIF.

    "行项目字段
    LOOP AT ct_vbpok ASSIGNING FIELD-SYMBOL(<fs_vbpok>).
      LOOP AT extension2 INTO ls_extension2 WHERE row = <fs_vbpok>-posnr_vl AND param = 'LIPS' .
        IF ls_extension2-field EQ 'ZCPXH'. "产品型号
          MOVE ls_extension2-value TO <fs_vbpok>-zcpxh.
        ENDIF.

        IF ls_extension2-field EQ 'ZWBXTBS'. "平台订单号
          MOVE ls_extension2-value TO <fs_vbpok>-zwbxtbs.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_005.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_006.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_007.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_008.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_011.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_012.
  endmethod.


  method IF_EX_SMOD_V50B0001~EXIT_SAPLV50K_013.
  endmethod.
ENDCLASS.
