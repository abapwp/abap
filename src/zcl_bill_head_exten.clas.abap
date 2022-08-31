class ZCL_BILL_HEAD_EXTEN definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_SD_BIL_EXT_HEAD .
protected section.
private section.
ENDCLASS.



CLASS ZCL_BILL_HEAD_EXTEN IMPLEMENTATION.


  METHOD if_sd_bil_ext_head~activate_tab_page.

    fcaption = '客制化屏幕'.
    fprogram = 'SAPLZFG_SD002'.
    fdynpro = '9000'.
  ENDMETHOD.


  method IF_SD_BIL_EXT_HEAD~TRANSFER_DATA_FROM_SUBSCREEN.
    DATA:LS_VBRK TYPE VBRK.
    CALL FUNCTION 'ZFM_BILL_HEAD_TODATA'
      IMPORTING
        OS_VBRK = LS_VBRK.
    FVBRK-ZDZFP = LS_VBRK-ZDZFP.

  endmethod.


  method IF_SD_BIL_EXT_HEAD~TRANSFER_DATA_TO_SUBSCREEN.
    CALL FUNCTION 'ZFM_BILL_HEAD_TOSCREEN'
       EXPORTING
         IS_VBRK  = F_VBRK.
  endmethod.
ENDCLASS.
