class ZEH_SD_LIPS_ITEM_001 definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_LE_SHP_TAB_CUST_ITEM .
protected section.
private section.
ENDCLASS.



CLASS ZEH_SD_LIPS_ITEM_001 IMPLEMENTATION.


  METHOD if_ex_le_shp_tab_cust_item~activate_tab_page.
    ef_caption     = '自定义字段'(001).
    ef_position    = 20.
    ef_program     = 'SAPLZFG_SD005'.
    ef_dynpro      = '9200'.
    cs_v50agl_cust = 'X'.
  ENDMETHOD.


  method IF_EX_LE_SHP_TAB_CUST_ITEM~PASS_FCODE_TO_SUBSCREEN.
  endmethod.


  METHOD if_ex_le_shp_tab_cust_item~transfer_data_from_subscreen.
    CALL FUNCTION 'ZFM_SD_ITEM_FROM_SUBSCREEN'
      IMPORTING
        es_lips = cs_lips.
  ENDMETHOD.


  method IF_EX_LE_SHP_TAB_CUST_ITEM~TRANSFER_DATA_TO_SUBSCREEN.
    CALL FUNCTION 'ZFM_SD_ITEM_TO_SUBSCREEN'
      EXPORTING
        IS_LIPS = IS_LIPS.
  endmethod.
ENDCLASS.
