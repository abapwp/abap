
FUNCTION ZFM_CHECK_FEILD.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  EXPORTING
*"     VALUE(EV_STATUS) TYPE  BAPIBAPI_MTYPE
*"     VALUE(EV_MESSAGE) TYPE  BAPIBAPI_MSG
*"  TABLES
*"      GT_FEILD TYPE  STANDARD TABLE OPTIONAL
*"      GT_TABLE TYPE  STANDARD TABLE OPTIONAL
*"----------------------------------------------------------------------

*-----表gt_feild是需要检验必输的所有字段，表字段结构只能定义有且只有一个任意字段
  DATA: BEGIN OF lt_field OCCURS 0,
          fieldnm TYPE txt30,
        END OF lt_field.
  DATA:cl_descr TYPE REF TO cl_abap_structdescr.
  FIELD-SYMBOLS:<fs_comp> TYPE abap_compdescr.

  CHECK gt_feild[] IS NOT INITIAL.

  "获取gt_feild 字段结构
  CLEAR lt_field[].
  cl_descr ?= cl_abap_typedescr=>describe_by_data( gt_feild ).
  LOOP AT cl_descr->components ASSIGNING <fs_comp>.
    APPEND <fs_comp>-name TO lt_field.
  ENDLOOP.

  READ TABLE lt_field INDEX 1.
  "逐一检查必输字段

  LOOP AT gt_table.
    LOOP AT gt_feild.
      ASSIGN COMPONENT  lt_field-fieldnm OF STRUCTURE gt_feild TO FIELD-SYMBOL(<fs_feild>).
      IF <fs_feild> IS ASSIGNED .
        ASSIGN COMPONENT  <fs_feild> OF STRUCTURE gt_table TO FIELD-SYMBOL(<fs_value>).
        IF <fs_value> IS ASSIGNED AND <fs_value> IS INITIAL.
          ev_status = 'E'.
          ev_message = ev_message && '--请输入必输字段' && <fs_feild> && '--'.
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDLOOP.

  IF ev_status NE 'E'.
    ev_status = 'S'.
  ENDIF.



ENDFUNCTION.
