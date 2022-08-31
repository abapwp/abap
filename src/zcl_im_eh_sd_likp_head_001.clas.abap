class ZCL_IM_EH_SD_LIKP_HEAD_001 definition
  public
  final
  create public .

public section.

  interfaces IF_EX_LE_SHP_TAB_CUST_HEAD .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_EH_SD_LIKP_HEAD_001 IMPLEMENTATION.


  METHOD if_ex_le_shp_tab_cust_head~activate_tab_page.
    ef_caption     = '自定义字段'(001).
    ef_position    = 20.
    ef_program     = 'SAPLZFG_SD005'.
    ef_dynpro      = '9100'.
    cs_v50agl_cust = 'X'.
  ENDMETHOD.


  method IF_EX_LE_SHP_TAB_CUST_HEAD~PASS_FCODE_TO_SUBSCREEN.
  endmethod.


  METHOD if_ex_le_shp_tab_cust_head~transfer_data_from_subscreen.
    CALL FUNCTION 'ZFM_SD_HEAD_FROM_SUBSCREEN'
      IMPORTING
        es_likp = cs_likp.
  ENDMETHOD.


  METHOD if_ex_le_shp_tab_cust_head~transfer_data_to_subscreen.

    CALL FUNCTION 'ZFM_SD_HEAD_TO_SUBSCREEN'
      EXPORTING
        is_likp = is_likp.

  ENDMETHOD.
ENDCLASS.
