*----------------------------------------------------------------------*
***INCLUDE LZFG_SD005O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_9100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_9100 OUTPUT.
FIELD-SYMBOLS <FS_ANY>.

  ASSIGN ('(SAPMV50A)T180-TRTYP') TO <FS_ANY>.
  IF <FS_ANY> IS ASSIGNED.
    LOOP AT SCREEN.
      IF <FS_ANY> = 'A'.
        SCREEN-INPUT = '0'.
      ELSE.
        IF GS_LIKP-WBSTK = 'C'.
          IF SCREEN-GROUP1 = 'Z1'.
            SCREEN-INPUT = '1'.
          ELSE.
            SCREEN-INPUT = '0'.
          ENDIF.
        ELSE.
          SCREEN-INPUT = '1'.
        ENDIF.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_9200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_9200 OUTPUT.
LOOP AT SCREEN.
    IF GS_LIPS-WBSTA = 'C'.
      SCREEN-INPUT = '0'.

      IF GC_EDITOR IS NOT INITIAL.
        GC_EDITOR->SET_READONLY_MODE( 1 ).
      ENDIF.
    ELSE.
      ASSIGN ('(SAPMV50A)T180-TRTYP') TO <FS_ANY>.
      IF <FS_ANY> IS ASSIGNED.
        IF <FS_ANY> = 'A'.
          SCREEN-INPUT = '0'.

          IF GC_EDITOR IS NOT INITIAL.
            GC_EDITOR->SET_READONLY_MODE( 1 ).
          ENDIF.
        ELSE.
          SCREEN-INPUT = '1'.

          IF GC_EDITOR IS NOT INITIAL.
            GC_EDITOR->SET_READONLY_MODE( 0 ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

ENDMODULE.
