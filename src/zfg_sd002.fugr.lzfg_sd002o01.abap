*----------------------------------------------------------------------*
***INCLUDE LZFG_SD002O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module MODIFY_SCREEN OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE modify_screen OUTPUT.
* SET PF-STATUS 'xxxxxxxx'.
* SET TITLEBAR 'xxx'.
  IF sy-tcode EQ 'VF03'.
    LOOP AT SCREEN.
      IF screen-group2 EQ 'EX'.
          screen-input = 0.
          MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDMODULE.
