***&---------------------------------------------------------------------***
***& Program Name  :  ZFNSD002          　　　　    ***
***& Title         :  特殊库存E转换程序                ***
***& Module Name   :  SD                        ***
***& Sub-Module    :                         ***
***& Author        :  王钢稀                      ***
***& Create Date   :  2022-08-11                  ***
***& Logical DB    :  NOTHING                     ***
***& Program Type   : FN                                ***
***&---------------------------------------------------------------------***
*& REVISION LOG                                                        *
*& LOG#     DATE       AUTHOR        DESCRIPTION                       *
*& ----     ----       ----------    -----------                       *
*& 0000  2022-08-11   王钢稀           CREATE                          *
************************************************************************

REPORT ZFNSD002.

TABLES: SSCRFIELDS,MARD,MSEG,MARA.
INCLUDE <LIST>.
INCLUDE <ICON>.

DATA:GM_HEAD    LIKE BAPI2017_GM_HEAD_01,
     GM_CODE    LIKE BAPI2017_GM_CODE,
     GM_DOC     LIKE BAPI2017_GM_HEAD_RET,
     LV_LINE    TYPE I,
     LV_MESSAGE TYPE BAPI_MSG,
     GS_ITEM    TYPE BAPI2017_GM_ITEM_CREATE,
     GT_ITEM    LIKE TABLE OF BAPI2017_GM_ITEM_CREATE,
     GS_GERNR   TYPE BAPI2017_GM_SERIALNUMBER,
     GT_GERNR   LIKE TABLE OF BAPI2017_GM_SERIALNUMBER,
     LT_RETURN  TYPE TABLE OF BAPIRET2,
     LS_RETURN  TYPE BAPIRET2.
DATA:LS_MBLNR TYPE BAPI2017_GM_HEAD_RET,
     MESSAGE  TYPE BAPI_MSG,
     LV_EBELP TYPE EKPO-EBELP,
     LV_MBLPO TYPE MSEG-ZEILE.

DATA: LV_BUKRS1 TYPE T001-BUKRS,
      LV_BUKRS2 TYPE T001-BUKRS,
      LV_BWTTY  TYPE MARC-BWTTY,
      LV_BWART  TYPE MSEG-BWART.



TYPES:BEGIN OF TY_MSEG,
        MBLNR   TYPE MSEG-MBLNR,
        MJAHR   TYPE MSEG-MJAHR,
        ZEILE   TYPE MSEG-ZEILE,
        XAUTO   TYPE MSEG-XAUTO,
        SGTXT   TYPE MSEG-SGTXT,
        INSMK   TYPE MSEG-INSMK,
        ZWMSDH  TYPE TXT20,
        ZWMSDHH TYPE TXT20,
      END OF TY_MSEG.
DATA:LT_MSEG TYPE TABLE OF TY_MSEG.


**定义接收内表：
TYPES:BEGIN OF TY_DATA,
        BOX       TYPE CHAR1,
        ICON      TYPE ICON-ID,         "指示灯
        MATNR     TYPE MCHB-MATNR,
        MAKTX     TYPE MAKT-MAKTX,
        WERKS     TYPE MCHB-WERKS,
        NAME1     TYPE T001W-NAME1,
        LGORT     TYPE MCHB-LGORT,
        LGOBE     TYPE T001L-LGOBE,
        CHARG     TYPE MCHB-CHARG,
        CLABS     TYPE MCHB-CLABS,
        CINSM     TYPE MCHB-CINSM,
        MEINS     TYPE MARA-MEINS,
        BWTAR     TYPE MSEG-BWTAR,
        SOBKZ     TYPE MSKA-SOBKZ,
        VBELN     TYPE MSKA-VBELN,
        POSNR     TYPE MSKA-POSNR,
        MAT_KDAUF TYPE MSEG-MAT_KDAUF,
        MAT_KDPOS TYPE MSEG-MAT_KDPOS,
        MBLNR     TYPE MKPF-MBLNR,
*        type    type  bapi_mtype,
        MESSAGE   TYPE  BAPI_MSG,
      END OF TY_DATA.
DATA:IT_DATA TYPE STANDARD TABLE OF TY_DATA,
     WA_DATA LIKE LINE OF IT_DATA.

DATA:LT_POST TYPE TABLE OF ZSSD002.
DATA:LS_POST TYPE ZSSD002.
DATA:LV_MATERDOC TYPE MKPF-MBLNR.
DATA:ET_RETURN  LIKE TABLE OF BAPIRET2.



*&---定义ALV显示的字段列及其描述等属性
DATA:GT_FIELDCAT TYPE  LVC_T_FCAT,
     GS_FIELDCAT TYPE  LVC_S_FCAT,
     GS_LAYOUT   TYPE LVC_S_LAYO.
DATA LS_STYLELIN TYPE LVC_S_STYL.

DATA:FUNCTION_KEY TYPE SMP_DYNTXT.         "功能按钮
SELECTION-SCREEN FUNCTION KEY 1.
*---------------------------------------------------------------------*
*       CLASS lcl_handle_events DEFINITION
*---------------------------------------------------------------------*
* §5.1 define a local class for handling events of cl_salv_table
*---------------------------------------------------------------------*
CLASS LCL_HANDLE_EVENTS DEFINITION.
  PUBLIC SECTION.
    METHODS:
      ON_USER_COMMAND FOR EVENT ADDED_FUNCTION OF CL_SALV_EVENTS
        IMPORTING E_SALV_FUNCTION.
ENDCLASS.                    "lcl_handle_events DEFINITION

*---------------------------------------------------------------------*
*       CLASS lcl_handle_events IMPLEMENTATION
*---------------------------------------------------------------------*
* §5.2 implement the events for handling the events of cl_salv_table
*---------------------------------------------------------------------*
CLASS LCL_HANDLE_EVENTS IMPLEMENTATION.
  METHOD ON_USER_COMMAND.
    PERFORM SET_FUNCTION USING E_SALV_FUNCTION TEXT-I08.
  ENDMETHOD.                    "on_user_command
ENDCLASS.                    "lcl_handle_events IMPLEMENTATION

SELECT-OPTIONS: S_MATNR FOR MARD-MATNR,
                S_MTART FOR MARA-MTART,
                S_MATKL FOR MARA-MATKL.

PARAMETERS:P_DATE TYPE EKBE-BUDAT DEFAULT SY-DATUM.

SELECTION-SCREEN BEGIN OF BLOCK A WITH FRAME TITLE TEXT-001.
  PARAMETERS:ZC_WERKS TYPE MARD-WERKS OBLIGATORY.
  PARAMETERS:ZC_LGORT TYPE MARD-LGORT OBLIGATORY.
SELECTION-SCREEN END OF BLOCK A.

SELECTION-SCREEN BEGIN OF BLOCK C WITH FRAME TITLE TEXT-003.
  PARAMETERS:P_E1 TYPE C RADIOBUTTON GROUP RADI USER-COMMAND SEL DEFAULT 'X'.
  PARAMETERS: P_E2 TYPE C RADIOBUTTON GROUP RADI.
  PARAMETERS: P_E3 TYPE C RADIOBUTTON GROUP RADI.
SELECTION-SCREEN END OF BLOCK C.


INITIALIZATION.




START-OF-SELECTION.
  PERFORM FRM_SET_DATA.
  PERFORM FRM_DISPLAY.

END-OF-SELECTION.
*&---------------------------------------------------------------------*
*& Form FRM_SET_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_SET_DATA .
  REFRESH:IT_DATA[].

  IF P_E1 IS NOT INITIAL OR P_E2 IS NOT INITIAL.    "  拿到 对应的 E 库存 数据  1 和 2 都是从 E库存开始
    SELECT
    A~MATNR,
    A~WERKS,
    A~LGORT,
    A~SOBKZ,     " 特殊库存标识
    A~CHARG,
    A~KALAB AS CLABS,  " 非限制使用的估价的库存
    A~VBELN,
    A~POSNR
    INTO TABLE @DATA(LT_STOCK) FROM MSKA AS A        "  MSKA 销售订单库存  MARA
    INNER JOIN MARA AS B
    ON A~MATNR = B~MATNR
    WHERE A~MATNR IN @S_MATNR
      AND A~WERKS EQ @ZC_WERKS
      AND A~LGORT EQ @ZC_LGORT
      AND B~MTART IN @S_MTART
      AND B~MATKL IN @S_MATKL
      AND KALAB GT 0.                                " 20220818  没有大于零的

  ENDIF.
  IF LT_STOCK[] IS NOT INITIAL.
    SORT LT_STOCK BY MATNR WERKS.
  ENDIF.

  IF P_E3 IS NOT INITIAL.                           "  从  非限制 库存 开始
    SELECT
    A~MATNR,
    A~WERKS,
    A~LGORT,
    A~SPERC AS SKOBZ,
    A~CHARG,
    A~CLABS              " 非限制使用的估价的库存
    INTO TABLE @DATA(LT_STOCK1) FROM MCHB AS A      " MCHB 批量库存 " 20220818  目前是空的   MARA
    INNER JOIN MARA AS B
    ON A~MATNR = B~MATNR
      WHERE A~MATNR IN @S_MATNR
        AND A~WERKS EQ @ZC_WERKS
        AND A~LGORT EQ @ZC_LGORT
        AND B~MTART IN @S_MTART
        AND B~MATKL IN @S_MATKL
    AND  CLABS GT 0.
*    CHECK LT_STOCK1[] IS NOT INITIAL.

    SELECT
    A~MATNR,
    A~WERKS,
    A~LGORT,
    A~EXPPG AS SOBKZ,
    A~LGPBE AS CHARG,
    A~LABST AS CLABS
    INTO TABLE @DATA(LT_STOCK2) FROM MARD AS A      " MARD 物料的仓储位置数据   MARA    MARC 物料的工厂数据
    INNER JOIN MARA AS B
    ON A~MATNR = B~MATNR
    INNER JOIN MARC AS C
    ON  A~MATNR = C~MATNR
    AND A~WERKS = C~WERKS
      WHERE A~MATNR IN @S_MATNR
        AND A~WERKS EQ @ZC_WERKS
        AND A~LGORT EQ @ZC_LGORT
        AND B~MTART IN @S_MTART
        AND B~MATKL IN @S_MATKL
        AND  LABST GT 0
        AND C~XCHAR NE 'X'.

    IF  LT_STOCK1[] IS NOT INITIAL.

      APPEND LINES OF LT_STOCK1 TO LT_STOCK.
    ENDIF.
    IF  LT_STOCK2[] IS NOT INITIAL.
      APPEND LINES OF LT_STOCK2 TO LT_STOCK.
    ENDIF.
    SORT LT_STOCK BY MATNR WERKS.
  ENDIF.



  "  拿到 对应 的物料 的 物料组，单位，   工厂对应的 名称   ，   库存 对应  地点
  SELECT
    MARA~MATNR,
    MARA~MEINS,
    MAKT~MAKTX
    INTO TABLE @DATA(LT_MARA)
    FROM MARA
    LEFT JOIN MAKT ON MAKT~MATNR = MARA~MATNR AND MAKT~SPRAS = @SY-LANGU
    FOR ALL ENTRIES IN @LT_STOCK[]
  WHERE MARA~MATNR = @LT_STOCK-MATNR.

  SELECT WERKS,
         NAME1
    INTO TABLE @DATA(LT_WERKS) FROM T001W
  WHERE  WERKS EQ  @ZC_WERKS.

  SELECT WERKS,
         LGORT,
         LGOBE
    INTO TABLE @DATA(LT_LGORT) FROM T001L
     WHERE  WERKS EQ @ZC_WERKS
  AND   LGORT EQ @ZC_LGORT .


  "  给 要显示  的内表  赋值
  LOOP AT LT_STOCK INTO DATA(LS_STOCK).
    CLEAR:LV_BWTTY.
    MOVE-CORRESPONDING LS_STOCK TO WA_DATA.
    READ TABLE LT_MARA INTO DATA(LS_MARA) WITH KEY MATNR = LS_STOCK-MATNR.
    IF SY-SUBRC EQ 0.
      WA_DATA-MEINS = LS_MARA-MEINS.
      WA_DATA-MAKTX = LS_MARA-MAKTX.
    ENDIF.

    READ TABLE LT_WERKS INTO DATA(LS_WERKS) WITH KEY WERKS = LS_STOCK-WERKS.
    IF SY-SUBRC EQ 0.
      WA_DATA-NAME1 = LS_WERKS-NAME1.
    ENDIF.

    READ TABLE LT_LGORT INTO DATA(LS_LGORT) WITH KEY WERKS = LS_STOCK-WERKS
                                                     LGORT = LS_STOCK-LGORT.
    IF SY-SUBRC EQ 0.
      WA_DATA-LGOBE = LS_LGORT-LGOBE.
    ENDIF.
    IF LS_STOCK-CHARG IS NOT INITIAL.
      SELECT SINGLE BWTAR INTO WA_DATA-BWTAR FROM MCHA
                                      WHERE  MATNR = LS_STOCK-MATNR
                                        AND  WERKS = LS_STOCK-WERKS
                                        AND  CHARG = LS_STOCK-CHARG.
    ENDIF.

    APPEND WA_DATA TO IT_DATA.

    CLEAR:LS_WERKS,LS_MARA,WA_DATA,LS_STOCK,LS_LGORT.
  ENDLOOP.

  REFRESH:LT_LGORT[],LT_WERKS[],LT_STOCK[].
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_DISPLAY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_DISPLAY .
  PERFORM FRM_SET_ALV.


*  perform frm_alv.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SET_ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_SET_ALV .
  SORT  IT_DATA.
  DELETE ADJACENT DUPLICATES FROM IT_DATA[] COMPARING ALL FIELDS.


  PERFORM INIT_LAYOUT.             " 设置ALV输出格式

  PERFORM INIT_FIELDCAT  .           " 设置ALV输出字段
  PERFORM FRM_DISPLAY_ALV TABLES IT_DATA.         " ALV输出

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_FUNCTION
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_SALV_FUNCTION
*&      --> TEXT_I08
*&---------------------------------------------------------------------*
FORM SET_FUNCTION  USING I_FUNCTION TYPE SALV_DE_FUNCTION
                             I_TEXT  TYPE STRING.

  CASE I_FUNCTION.
    WHEN '&TRANSFER1'.
      PERFORM FRM_SAVE.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_SAVE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_SAVE .
  "  需求 类型 对应  的  表字段   VBAP-BEDAE
  REFRESH:ET_RETURN[].
  LOOP AT IT_DATA INTO DATA(LS_ITDATA) WHERE BOX = 'X'.
    LV_EBELP = LV_EBELP + 1.
    GS_ITEM-LINE_ID = LV_EBELP.
    GS_ITEM-MATERIAL     = LS_ITDATA-MATNR."物料号
    GS_ITEM-PLANT        = LS_ITDATA-WERKS."工厂
    GS_ITEM-STGE_LOC     = LS_ITDATA-LGORT."库存地点
    GS_ITEM-MOVE_STLOC   = LS_ITDATA-LGORT.
    GS_ITEM-BATCH        = LS_ITDATA-CHARG."批号
    GS_ITEM-MOVE_BATCH   = LS_ITDATA-CHARG."调入批次

    GS_ITEM-ENTRY_QNT    = LS_ITDATA-CLABS."以录入项单位表示的数量


    GS_ITEM-ENTRY_UOM    = LS_ITDATA-MEINS."以录入项单位


    GS_ITEM-MOVE_PLANT   = ZC_WERKS."调入工厂
    GS_ITEM-MOVE_STLOC   = ZC_LGORT."调入库存地
    IF P_E1 EQ 'X' OR P_E3 EQ 'X'.

      GS_ITEM-SALES_ORD      = LS_ITDATA-MAT_KDAUF."销售订单号
      GS_ITEM-S_ORD_ITEM     = LS_ITDATA-MAT_KDPOS."销售订单行项目
      GS_ITEM-MOVE_TYPE = '413'.  " 从 非限制 库开始

    ENDIF.

    IF P_E1 EQ 'X' OR P_E2 EQ 'X'.

      GS_ITEM-SPEC_STOCK = 'E'.  " 从 E 库 开始
      GS_ITEM-VAL_SALES_ORD = LS_ITDATA-VBELN.
      GS_ITEM-VAL_S_ORD_ITEM = LS_ITDATA-POSNR.
      GS_ITEM-VAL_TYPE = LS_ITDATA-BWTAR.
    ELSE.
      GS_ITEM-SPEC_STOCK = ''.
    ENDIF.

    IF P_E2 EQ 'X'.
      GS_ITEM-MOVE_TYPE = '411'.
    ENDIF.


*      gs_item-move_val_type = ls_itdata-umbar.


    IF LS_ITDATA-MATNR NE GS_ITEM-MATERIAL.

      GS_ITEM-MATERIAL_LONG = LS_ITDATA-MATNR.
    ENDIF.
    APPEND GS_ITEM TO GT_ITEM.
    CLEAR:GS_ITEM.
  ENDLOOP.
  CLEAR:LV_EBELP,LV_MBLPO.
  GM_HEAD-PSTNG_DATE = P_DATE.
  GM_HEAD-DOC_DATE   = SY-DATUM.
  GM_CODE = '04'.      " MB1B
  CLEAR:GM_DOC.
  CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
    EXPORTING
      GOODSMVT_HEADER  = GM_HEAD
      GOODSMVT_CODE    = GM_CODE
    IMPORTING
      GOODSMVT_HEADRET = LS_MBLNR
    TABLES
      GOODSMVT_ITEM    = GT_ITEM
*     goodsmvt_serialnumber = gt_gernr
      RETURN           = LT_RETURN.

  IF LINE_EXISTS( LT_RETURN[ TYPE = 'E' ] )
  OR LINE_EXISTS( LT_RETURN[ TYPE = 'A' ] )  .
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    LS_ITDATA-ICON = '@5C@'." 红灯
    LOOP AT LT_RETURN INTO LS_RETURN WHERE TYPE = 'E'.
      LS_ITDATA-MESSAGE = LS_ITDATA-MESSAGE && LS_RETURN-MESSAGE .
    ENDLOOP.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        WAIT = 'X'.
    LS_ITDATA-ICON = '@5B@'." 绿灯
    LS_ITDATA-MBLNR = LS_MBLNR-MAT_DOC.
    LS_ITDATA-MESSAGE = '物料凭证' && LS_ITDATA-MBLNR && '创建成功'.
  ENDIF.
  "  根据 icon  mblnr  message  字段 来 修改 内表
  MODIFY IT_DATA FROM LS_ITDATA TRANSPORTING ICON MBLNR MESSAGE WHERE  BOX = 'X'.
  CLEAR:GT_ITEM,GT_ITEM[],GM_HEAD,GM_CODE,LS_MBLNR,GT_GERNR,GT_GERNR[],LT_RETURN,LT_RETURN[].
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  INIT_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INIT_LAYOUT .
  CLEAR GS_LAYOUT.
  GS_LAYOUT-ZEBRA      = 'X' .    " 斑马线
  GS_LAYOUT-CWIDTH_OPT = 'X' .    " 自动调整ALVL列宽
  GS_LAYOUT-BOX_FNAME  = 'BOX'.  " 选择框
*  gs_layout-stylefname = 'FIELD_STYLE'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INIT_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INIT_FIELDCAT .

  CLEAR GT_FIELDCAT.
  DEFINE ADD_FIELDCAT.
    CLEAR GS_FIELDCAT.
    GS_FIELDCAT-FIELDNAME    =  &1.
    GS_FIELDCAT-COLTEXT      =  &2.
    GS_FIELDCAT-JUST         =  &3.
    GS_FIELDCAT-OUTPUTLEN    =  &4.
    GS_FIELDCAT-HOTSPOT       =  &5.
    GS_FIELDCAT-EDIT         =  &6.
    GS_FIELDCAT-CHECKBOX     =  &7.
    GS_FIELDCAT-REF_TABLE    =  &8.  "REF_TABNAME
    GS_FIELDCAT-REF_FIELD    =  &9.  "REF_FIELDNAME

    APPEND GS_FIELDCAT   TO GT_FIELDCAT.
  END-OF-DEFINITION.
  ADD_FIELDCAT   'ICON'     '信号灯'                    '' '20'  ''  ''  ''  ''  ''   .
  ADD_FIELDCAT   'MATNR'     '物料号'                    '' '20'  ''  ''  ''  'MARA'  'MATNR'   .
  ADD_FIELDCAT   'MAKTX'     '物料描述'                    '' '20'  ''  ''  ''  'MAKT'  'MAKTX'   .
  ADD_FIELDCAT   'WERKS'     '工厂'                    '' '20'  ''  ''  ''  'MARC'  'WERKS'   .
  ADD_FIELDCAT   'NAME1'     '工厂描述'                    '' '20'  ''  ''  ''  'T001W'  'NAME1'   .
  ADD_FIELDCAT   'LGORT'     '库存地点'                    '' '20'  ''  ''  ''  'MARD'  'LGORT'   .
  ADD_FIELDCAT   'LGOBE'     '库存地点描述'                    '' '20'  ''  ''  ''  'T001L'  'LGOBE'   .
  ADD_FIELDCAT   'SOBKZ'     '特殊库存标识'                    '' '20'  ''  ''  ''  'MSKA'  'SOBKZ'   .
  ADD_FIELDCAT   'CHARG'     '批次'                    '' '20'  ''  ''  ''  'MCHB'  'CHARG'   .
  ADD_FIELDCAT   'CLABS'     '非限制使用库存'                    '' '20'  ''  'X'  ''  'MCHB'  'CLABS'   .
  ADD_FIELDCAT   'MEINS'     '单位'                    '' '20'  ''  ''  ''  'MARA'  'MEINS'   .
  ADD_FIELDCAT   'BWTAR'     '评估类型'                    '' '20'  ''  ''  ''  'MSEG'  'BWTAR'   .

  IF P_E1 IS NOT INITIAL OR P_E2 IS NOT INITIAL.
    ADD_FIELDCAT   'VBELN'     '销售订单'                    '' '20'  ''  ''  ''  'MSKA'  'VBELN'   .
    ADD_FIELDCAT   'POSNR'     '销售订单行项目'                    '' '20'  ''  ''  ''  'MSKA'  'POSNR'   .
  ENDIF .
  IF P_E1 IS NOT INITIAL OR P_E3 IS NOT INITIAL.
    ADD_FIELDCAT   'MAT_KDAUF'     '调入销售订单'                    '' '20'  ''  'X'  ''  'VBAP'  'VBELN'   .
    ADD_FIELDCAT   'MAT_KDPOS'     '调入销售订单行项目'                    '' '20'  ''  'X'  ''  'VBAP'  'POSNR'   .
  ENDIF.

  ADD_FIELDCAT   'MBLNR'     '物料凭证编号'              '' '20'  ''  ''  ''  'MSEG'  'MBLNR'   .
*  add_fieldcat   'TYPE'      '消息类型: S 成功,E 错误,W 警告,I 信息,A 中断'                    '' '20'  ''  ''  ''  ''  ''   .
  ADD_FIELDCAT   'MESSAGE'   '消息文本'                    '' '20'  ''  ''  ''  ''  ''   .
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FRM_DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FRM_DISPLAY_ALV TABLES PT_OUTTAB.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      I_CALLBACK_PROGRAM       = SY-REPID
      I_CALLBACK_PF_STATUS_SET = 'FRM_PF_STATUS'
      I_CALLBACK_USER_COMMAND  = 'FRM_USER_COMMAND'
*     i_callback_html_top_of_page = 'FRM_HTML_TOP_OF_PAGE'
*     i_grid_settings          = l_grid_settings
      IS_LAYOUT_LVC            = GS_LAYOUT
      IT_FIELDCAT_LVC          = GT_FIELDCAT[]
      I_DEFAULT                = 'X'
      I_SAVE                   = 'A'
*     it_events                = it_events
    TABLES
      T_OUTTAB                 = PT_OUTTAB
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
             WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_DISPLAY                                              *
*&---------------------------------------------------------------------*
*&       ALV工具栏状态                                                 *
*&---------------------------------------------------------------------*
*&  -->  p1    text                                                    *
*&  <--  p2    text                                                    *
*&---------------------------------------------------------------------*
FORM FRM_PF_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB.
  SET PF-STATUS 'STANDARD'.
ENDFORM.                    "FRM_PF_STATUS
*&---------------------------------------------------------------------*
*&      Form  FRM_DISPLAY                                              *
*&---------------------------------------------------------------------*
*&       ALV工具栏命令                                                 *
*&---------------------------------------------------------------------*
*&  -->  p1    text                                                    *
*&  <--  p2    text                                                    *
*&---------------------------------------------------------------------*
FORM FRM_USER_COMMAND  USING R_UCOMM LIKE SY-UCOMM
                        RS_SELFIELD TYPE SLIS_SELFIELD.
*&---刷新屏幕数据到内表
  DATA: LR_GRID1 TYPE REF TO CL_GUI_ALV_GRID.
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      E_GRID = LR_GRID1.
  CALL METHOD LR_GRID1->CHECK_CHANGED_DATA.
*&---错误处理标识
  DATA:LV_FLAG TYPE C.
  CLEAR:LV_FLAG.

*&---按钮功能实现
  CASE R_UCOMM.
    WHEN '&TRANSFER1'.
      PERFORM FRM_SAVE.
  ENDCASE.
*&---调用后数据保存处理
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      E_GRID = LR_GRID1.
  CALL METHOD LR_GRID1->CHECK_CHANGED_DATA.
  RS_SELFIELD-REFRESH = 'X' .
ENDFORM.                    "FRM_USER_COMMAND
