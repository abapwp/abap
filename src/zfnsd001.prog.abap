*&---------------------------------------------------------------------*
*& Program Name     : ZFNSD001                          　　　　       *
*& Title            : 客户主数据批导                                   *
*& Module Name      : SD                                               *
*& Sub-Module       :                                                  *
*& Author           : 唐金容                                           *
*& Create Date      : 2022-08-10                                       *
*& Logical DB       : NOTHING                                          *
*& Program Type     : Report                                           *
*&---------------------------------------------------------------------*
*& REVISION LOG                                                        *
*& LOG#     DATE       AUTHOR        DESCRIPTION                       *
*& ----     ----       ----------    -----------                       *
************************************************************************
REPORT zfnsd001.

TABLES:sscrfields.

*&---------------------------------------------------------------------*
*&----------------------------TYPES定义--------------------------------*
*&---------------------------------------------------------------------*
"基本数据
TYPES:BEGIN OF ty_jb_excel,
        zflag      TYPE zssd001_basic-zflag,                          "更新标识
        ktokd      TYPE zssd001_basic-ktokd,                          "客户账号组
        kukla      TYPE zssd001_basic-kukla,                          "客户分类
        kunnr      TYPE zssd001_basic-kunnr,                          "客户编号
*        found_dat  TYPE zssd001_basic-found_dat,                      "旧系统客户创建日期
        name1      TYPE zssd001_basic-name1,                          "客户名称
        mcod1      TYPE zssd001_basic-mcod1,                          "简称
        mcod2      TYPE zssd001_basic-mcod2,                          "简称2
        land1      TYPE zssd001_basic-land1,                          "国家
        regio      TYPE zssd001_basic-regio,                          "省
        ort01      TYPE zssd001_basic-ort01,                          "市
        comph      TYPE zssd001_basic-comph,                          "区/县
        pstlz      TYPE zssd001_basic-pstlz,                          "邮政编码
        spras      TYPE zssd001_basic-spras,                          "语言代码
        name_co    TYPE zssd001_basic-name_co,                        "采购员
        telf1      TYPE zssd001_basic-telf1,                          "联系电话
        smtp_addr  TYPE zssd001_basic-smtp_addr,                      "电子邮箱
        telfx      TYPE zssd001_basic-telfx,                          "传真
        str        TYPE char140,                                      "收货地址
        taxtype    TYPE zssd001_basic-taxtype,                        "税号类别
        taxnum     TYPE zssd001_basic-taxnum,                         "税号
        waers      TYPE zssd001_basic-waers,                          "货币码
        cap_incr_a TYPE zssd001_basic-cap_incr_a,                     "注册资本
      END OF ty_jb_excel.
TYPES:BEGIN OF ty_other,
*        SEL      TYPE CHAR1,
        icon(4)  TYPE c,
        ztype    TYPE zssd001_basic-ztype,                          "消息类型
        zmessage TYPE zssd001_basic-zmessage,                       "消息文本
      END OF ty_other.
DATA:gt_jb_excel TYPE STANDARD TABLE OF ty_jb_excel,
     gs_jb_excel TYPE ty_jb_excel.
TYPES:BEGIN OF ty_jb.
        INCLUDE TYPE ty_jb_excel.
        INCLUDE TYPE ty_other.
TYPES:END OF ty_jb.
DATA:gt_jb TYPE STANDARD TABLE OF ty_jb,
     gs_jb TYPE ty_jb.

"公司代码
TYPES:BEGIN OF ty_gs_excel,
        zflag TYPE zssd001_fi-zflag,                               "更新标识
        kunnr TYPE zssd001_fi-kunnr,                               "客户编号
        bukrs TYPE zssd001_fi-bukrs,                               "公司代码
        akont TYPE zssd001_fi-akont,                               "统驭科目
        zterm TYPE zssd001_fi-zterm,                               "付款条件
        zuawa TYPE zssd001_fi-zuawa,                               "排序码
*        altkn TYPE zssd001_fi-altkn,                               "旧系统客户编号
      END OF ty_gs_excel.
DATA:gt_gs_excel  TYPE STANDARD TABLE OF ty_gs_excel,
     gs_kgs_excel TYPE ty_gs_excel.
TYPES:BEGIN OF ty_gs.
        INCLUDE TYPE ty_gs_excel.
        INCLUDE TYPE ty_other.
TYPES:END OF ty_gs.
DATA:gt_gs  TYPE STANDARD TABLE OF ty_gs,
     gs_kgs TYPE ty_gs.

"销售
TYPES:BEGIN OF ty_xs_excel,
        zflag   TYPE zssd001_sales-zflag,                            "更新标识
        kunnr   TYPE zssd001_sales-kunnr,                            "客户编号
        vkorg   TYPE zssd001_sales-vkorg,                            "销售组织
        vtweg   TYPE zssd001_sales-vtweg,                            "分销渠道
        spart   TYPE zssd001_sales-spart,                            "产品组
        vkbur   TYPE zssd001_sales-vkbur,                            "销售部门
        vkgrp   TYPE zssd001_sales-vkgrp,                            "销售组
        bzirk   TYPE zssd001_sales-bzirk,                            "销售区域
        klabc   TYPE zssd001_sales-klabc,                            "客户等级
        zywyn   TYPE zssd001_sales-zywyn,                            "拓展业务员
        waers   TYPE zssd001_sales-waers,                            "货币
        kalks   TYPE zssd001_sales-kalks,                            "客户是否含税
        vsbed   TYPE zssd001_sales-vsbed,                            "装运条件
        kzazu   TYPE zssd001_sales-kzazu,                            "订单组合
        vwerk   TYPE zssd001_sales-vwerk,                            "交货工厂
        inco1   TYPE zssd001_sales-inco1,                            "国贸条件1
        inco2_l TYPE zssd001_sales-inco2_l,                          "发运港
        zterm   TYPE zssd001_sales-zterm,                            "付款条件
        ktgrd   TYPE zssd001_sales-ktgrd,                            "账户分配组
        taxkd   TYPE zssd001_sales-taxkd,                            "税分类
      END OF ty_xs_excel.
DATA:gt_xs_excel TYPE STANDARD TABLE OF ty_xs_excel,
     gs_xs_excel TYPE ty_xs_excel.
TYPES:BEGIN OF ty_xs.
        INCLUDE TYPE ty_xs_excel.
        INCLUDE TYPE ty_other.
TYPES:END OF ty_xs.
DATA:gt_xs TYPE STANDARD TABLE OF ty_xs,
     gs_xs TYPE ty_xs.

"信用
TYPES:BEGIN OF ty_xy_excel,
        zflag            TYPE zssd001_ukm-zflag,                      "更新标识
        kunnr            TYPE zssd001_ukm-kunnr,                      "客户编号
        risk_class       TYPE zssd001_ukm-risk_class,                 "风险类
        limit_rule       TYPE zssd001_ukm-limit_rule,                 "计算得分和信用额度的规则
        check_rule       TYPE zssd001_ukm-check_rule,                 "检查规则
        credit_sgmnt     TYPE zssd001_ukm-credit_sgmnt,               "信用段
        credit_limit     TYPE zssd001_ukm-credit_limit,               "信用额度
        limit_valid_date TYPE zssd001_ukm-limit_valid_date,           "有效终止日期
      END OF ty_xy_excel.
DATA:gt_xy_excel TYPE STANDARD TABLE OF ty_xy_excel,
     gs_xy_excel TYPE ty_xy_excel.
TYPES:BEGIN OF ty_xy.
        INCLUDE TYPE ty_xy_excel.
        INCLUDE TYPE ty_other.
TYPES:END OF ty_xy.
DATA:gt_xy TYPE STANDARD TABLE OF ty_xy,
     gs_xy TYPE ty_xy.

*"银行
*TYPES:BEGIN OF ty_yh_excel,
*        zflag   TYPE zssd001_knbk-zflag,                             "更新标识
*        kunnr   TYPE zssd001_knbk-kunnr,                             "客户编号
*        bkvid   TYPE zssd001_knbk-bkvid,                             "标识
*        banks   TYPE zssd001_knbk-banks,                             "国家
*        bankl   TYPE zssd001_knbk-bankl,                             "银行代码
*        banef   TYPE char38,                                         "开户账号
*        banka   TYPE zssd001_knbk-banka,                             "开户银行
*        accname TYPE zssd001_knbk-accname,                           "开票名称
*        ortas   TYPE char70,                                         "开票地址
*        but0bk  TYPE zssd001_knbk-but0bk,                            "开票电话'
*        "
**        bankn    TYPE zssd001_knbk-bankn,                             "银行账号
**        bkref    TYPE zssd001_knbk-bkref,                             "银行细目的参考明细
**        ort01    TYPE zssd001_knbk-ort01,                             "城市
**        stras    TYPE zssd001_knbk-stras,                             "街道
*      END OF ty_yh_excel.
*DATA:gt_yh_excel TYPE STANDARD TABLE OF ty_yh_excel,
*     gs_yh_excel TYPE ty_yh_excel.
*TYPES:BEGIN OF ty_yh.
*        INCLUDE TYPE ty_yh_excel.
*        INCLUDE TYPE ty_other.
*TYPES:END OF ty_yh.
*DATA:gt_yh TYPE STANDARD TABLE OF ty_yh,
*     gs_yh TYPE ty_yh.
*
*"合作伙伴
*TYPES:BEGIN OF ty_hb_excel,
*        zflag TYPE zssd001_parvw-zflag,                            "更新标识
*        kunnr TYPE zssd001_parvw-kunnr,                            "客户编号
*        vkorg TYPE zssd001_parvw-vkorg,                            "销售组织
*        vtweg TYPE zssd001_parvw-vtweg,                            "分销渠道
*        spart TYPE zssd001_parvw-spart,                            "产品组
*        parvw TYPE zssd001_parvw-parvw,                            "合作伙伴职能
*        parza TYPE zssd001_parvw-parza,                            "合作伙伴计数器
*        kunn2 TYPE zssd001_parvw-kunn2,                            "业务伙伴的客户号
*        knref TYPE zssd001_parvw-knref,                            "描述
*      END OF ty_hb_excel.
*DATA:gt_hb_excel TYPE STANDARD TABLE OF ty_hb_excel,
*     gs_hb_excel TYPE ty_hb_excel.
*TYPES:BEGIN OF ty_hb.
*        INCLUDE TYPE ty_hb_excel.
*        INCLUDE TYPE ty_other.
*TYPES:END OF ty_hb.
*DATA:gt_hb TYPE STANDARD TABLE OF ty_hb,
*     gs_hb TYPE ty_hb.

"客户主数据
TYPES:BEGIN OF ty_qb_excel.
        INCLUDE TYPE ty_jb_excel.  "客户主数据-基本数据
*TYPES:  bkvid            TYPE zssd001_knbk-bkvid,                             "标识
*        banks            TYPE zssd001_knbk-banks,                             "国家
*        bankl            TYPE zssd001_knbk-bankl,                             "银行代码
*        banef            TYPE char255,                                         "开户账号
*        banka            TYPE zssd001_knbk-banka,                             "开户银行
*        accname          TYPE zssd001_knbk-accname,                           "开票名称
*        ortas            TYPE char255,                                         "开票地址
*        but0bk           TYPE zssd001_knbk-but0bk,                            "开票电话'
TYPES:  vkorg            TYPE zssd001_sales-vkorg,                            "销售组织
        vtweg            TYPE zssd001_sales-vtweg,                            "分销渠道
        spart            TYPE zssd001_sales-spart,                            "产品组
        vkbur            TYPE zssd001_sales-vkbur,                            "销售部门
        vkgrp            TYPE zssd001_sales-vkgrp,                            "销售组
        bzirk            TYPE zssd001_sales-bzirk,                            "销售区域
        klabc            TYPE zssd001_sales-klabc,                            "客户等级
        zywyn            TYPE zssd001_sales-zywyn,                            "拓展业务员
        waers1           TYPE zssd001_sales-waers,                            "货币
        kalks            TYPE zssd001_sales-kalks,                            "客户是否含税
        vsbed            TYPE zssd001_sales-vsbed,                            "装运条件
        kzazu            TYPE zssd001_sales-kzazu,                            "订单组合
        vwerk            TYPE zssd001_sales-vwerk,                            "交货工厂
        inco1            TYPE zssd001_sales-inco1,                            "国贸条件1
        inco2_l          TYPE zssd001_sales-inco2_l,                          "发运港
        zterm1           TYPE zssd001_sales-zterm,                            "付款条件
        ktgrd            TYPE zssd001_sales-ktgrd,                            "账户分配组
        taxkd            TYPE zssd001_sales-taxkd,                            "税分类
        bukrs            TYPE zssd001_fi-bukrs,                               "公司代码
        akont            TYPE zssd001_fi-akont,                               "统驭科目
        zterm            TYPE zssd001_fi-zterm,                               "付款条件
        zuawa            TYPE zssd001_fi-zuawa,                               "排序码
*        altkn            TYPE zssd001_fi-altkn,                               "旧系统客户编号
        risk_class       TYPE zssd001_ukm-risk_class,                         "风险类
        limit_rule       TYPE zssd001_ukm-limit_rule,                         "计算得分和信用额度的规则
        check_rule       TYPE zssd001_ukm-check_rule,                         "检查规则
        credit_sgmnt     TYPE zssd001_ukm-credit_sgmnt,                       "信用段
        credit_limit     TYPE zssd001_ukm-credit_limit,                       "信用额度
        limit_valid_date TYPE zssd001_ukm-limit_valid_date.                   "有效终止日期
TYPES:END OF ty_qb_excel.
DATA:gt_qb_excel TYPE STANDARD TABLE OF ty_qb_excel,
     gs_qb_excel TYPE ty_qb_excel.
TYPES:BEGIN OF ty_qb.
        INCLUDE TYPE ty_qb_excel.
        INCLUDE TYPE ty_other.
TYPES:END OF ty_qb.
DATA:gt_qb TYPE STANDARD TABLE OF ty_qb,
     gs_qb TYPE ty_qb.

CONSTANTS:c_qb_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_QB',
          c_jb_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_JB',
          c_gs_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_GS',
          c_xs_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_XS',
          c_xy_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_XY',
*          c_yh_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_YH',
*          c_hb_mod       TYPE wwwdatatab-objid VALUE 'ZSDR001_HB',
          c_qb_file_name TYPE localfile        VALUE '\客户主数据导入模板.xls',
          c_jb_file_name TYPE localfile        VALUE '\客户主数据-常规数据导入模板.xls',
          c_gs_file_name TYPE localfile        VALUE '\客户主数据-公司代码数据导入模板.xls',
          c_xs_file_name TYPE localfile        VALUE '\客户主数据-销售视图数据导入模板.xls',
          c_xy_file_name TYPE localfile        VALUE '\客户信用主数据导入模板.xls'.
*          c_yh_file_name TYPE localfile        VALUE '\客户主数据-银行视图数据导入模板.xls',
*          c_hb_file_name TYPE localfile        VALUE '\客户主数据-合作伙伴数据导入模板.xls'.

*&---------------------------------------------------------------------*
*&-----------------------------DATA定义--------------------------------*
*&---------------------------------------------------------------------*
DATA: g_path TYPE rlgrap-filename.
DATA: gt_raw  TYPE truxs_t_text_data.   ""系统函数必须的变量定义
DATA: gt_filename TYPE TABLE OF file_table WITH HEADER LINE.
*---FOR ALV
DATA: gs_layout           TYPE slis_layout_alv,
      gt_field            TYPE slis_t_fieldcat_alv,
      gt_list_top_of_page TYPE slis_t_listheader,
      gs_field            LIKE LINE OF gt_field.

*&---------------------------------------------------------------------*
*&--------------------------选择屏幕逻辑块-----------------------------*
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS:r_qb   RADIOBUTTON GROUP gp1 USER-COMMAND zb DEFAULT 'X'.
    SELECTION-SCREEN: COMMENT 3(18) TEXT-016.
    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_qb.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS:r_jb   RADIOBUTTON GROUP gp1 .
    SELECTION-SCREEN: COMMENT 3(18) TEXT-002.
    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_jb.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS:r_gs   RADIOBUTTON GROUP gp1.
    SELECTION-SCREEN: COMMENT 3(20) TEXT-004.
    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_gs.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS:r_xs   RADIOBUTTON GROUP gp1.
    SELECTION-SCREEN: COMMENT 3(20) TEXT-005.
    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_xs.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS:r_xy   RADIOBUTTON GROUP gp1.
    SELECTION-SCREEN: COMMENT 3(20) TEXT-006.
    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_xy.
  SELECTION-SCREEN END OF LINE.

*  SELECTION-SCREEN BEGIN OF LINE.
*    PARAMETERS:r_yh   RADIOBUTTON GROUP gp1.
*    SELECTION-SCREEN: COMMENT 3(20) TEXT-007.
*    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_yh.
*  SELECTION-SCREEN END OF LINE.
*
*  SELECTION-SCREEN BEGIN OF LINE.
*    PARAMETERS:r_hb   RADIOBUTTON GROUP gp1.
*    SELECTION-SCREEN: COMMENT 3(20) TEXT-008.
*    SELECTION-SCREEN: PUSHBUTTON 25(12)  TEXT-003 USER-COMMAND c_hb.
*  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-009.
  PARAMETERS:p_file   TYPE rlgrap-filename.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN: COMMENT 3(20) TEXT-010.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN: COMMENT 3(60) TEXT-011.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN: COMMENT 3(60) TEXT-012.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN: COMMENT 3(60) TEXT-013.
SELECTION-SCREEN END OF LINE.

*SELECTION-SCREEN BEGIN OF LINE.
*  SELECTION-SCREEN: COMMENT 3(60) TEXT-014.
*SELECTION-SCREEN END OF LINE.
*
*SELECTION-SCREEN BEGIN OF LINE.
*  SELECTION-SCREEN: COMMENT 3(60) TEXT-015.
*SELECTION-SCREEN END OF LINE.

INITIALIZATION.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM get_file USING 1.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'C_JB'.
      PERFORM frm_downtemplate USING c_jb_mod c_jb_file_name.
    WHEN 'C_GS'.
      PERFORM frm_downtemplate USING c_gs_mod c_gs_file_name.
    WHEN 'C_XS'.
      PERFORM frm_downtemplate USING c_xs_mod c_xs_file_name.
    WHEN 'C_XY'.
      PERFORM frm_downtemplate USING c_xy_mod c_xy_file_name.
*    WHEN 'C_YH'.
*      PERFORM frm_downtemplate USING c_yh_mod c_yh_file_name.
*    WHEN 'C_HB'.
*      PERFORM frm_downtemplate USING c_hb_mod c_hb_file_name.
    WHEN 'C_QB'.
      PERFORM frm_downtemplate USING c_qb_mod c_qb_file_name.
    WHEN OTHERS.
  ENDCASE.

*&---------------------------------------------------------------------*
*&--------------------------数据处理-----------------------------------*
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM frm_check_input_data.
  PERFORM frm_get_excel_data.

*&---------------------------------------------------------------------*
*&      Form  FRM_DOWNTEMPLATE
*&---------------------------------------------------------------------*
*       下载模板
*----------------------------------------------------------------------*
*      -->P_1      text
*      -->P_2      text
*----------------------------------------------------------------------*
FORM frm_downtemplate USING p_mod p_file_name.
  DATA: l_object LIKE wwwdatatab,
        l_rc     TYPE sy-subrc,
        l_text   TYPE string.
  PERFORM search_help_path CHANGING g_path.
  SELECT SINGLE relid objid FROM wwwdata INTO CORRESPONDING FIELDS OF l_object WHERE srtf2 = 0
  AND objid = p_mod.
  IF sy-subrc <> 0 OR l_object-objid = space.
    CONCATENATE 'Template:' p_mod ' does not exist, please run T-code SMW0 to upload the template!' INTO l_text.
    MESSAGE l_text TYPE 'E'.
  ENDIF.
  CONCATENATE g_path p_file_name INTO g_path.
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = l_object
      destination = g_path
    IMPORTING
      rc          = l_rc
*   CHANGING
*     TEMP        =
    .
  IF sy-subrc <> 0.
    CONCATENATE 'template:' p_mod 'download failed' INTO l_text.
    MESSAGE l_text TYPE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SEARCH_HELP_PATH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PATH  text
*----------------------------------------------------------------------*
FORM search_help_path  CHANGING p_path.
  DATA: l_path TYPE string .
  CALL METHOD cl_gui_frontend_services=>directory_browse
    EXPORTING
      window_title         = '选择文件目录'
*     initial_folder       = 'C:\TEMP'
    CHANGING
      selected_folder      = l_path
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  p_path = l_path .
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_GET_EXCEL_JBDATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM frm_get_excel_data .

  IF r_jb = 'X'."1、客户主数据-基本数据
    FREE:gt_jb_excel,gt_jb.
    PERFORM frm_convert_xls_to_sap TABLES gt_jb_excel.
    LOOP AT  gt_jb_excel INTO gs_jb_excel.
      MOVE-CORRESPONDING gs_jb_excel TO gs_jb.
      APPEND gs_jb TO gt_jb.
    ENDLOOP.
    PERFORM frm_display_alv TABLES gt_jb.
  ELSEIF r_gs = 'X'."2、客户主数据-公司代码数据
    FREE:gt_gs_excel,gt_gs.
    PERFORM frm_convert_xls_to_sap TABLES gt_gs_excel.
    LOOP AT  gt_gs_excel INTO gs_kgs_excel.
      MOVE-CORRESPONDING gs_kgs_excel TO gs_kgs.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = gs_kgs-kunnr
        IMPORTING
          output = gs_kgs-kunnr.
      APPEND gs_kgs TO gt_gs.
    ENDLOOP.
    PERFORM frm_display_alv TABLES gt_gs.
  ELSEIF r_xs = 'X'."3、客户主数据-销售视图数据
    FREE: gt_xs_excel,gt_xs. "释放表
    PERFORM frm_convert_xls_to_sap TABLES gt_xs_excel.
    LOOP AT  gt_xs_excel INTO gs_xs_excel.
      MOVE-CORRESPONDING gs_xs_excel TO gs_xs.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = gs_xs-kunnr
        IMPORTING
          output = gs_xs-kunnr.
      APPEND gs_xs TO gt_xs.
    ENDLOOP.
    PERFORM frm_display_alv TABLES gt_xs.
  ELSEIF r_xy = 'X'."4、客户信用主数据
    FREE: gt_xy_excel,gt_xy.
    PERFORM frm_convert_xls_to_sap TABLES gt_xy_excel.
    LOOP AT  gt_xy_excel INTO gs_xy_excel.
      MOVE-CORRESPONDING gs_xy_excel TO gs_xy.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = gs_xy-kunnr
        IMPORTING
          output = gs_xy-kunnr.
      APPEND gs_xy TO gt_xy.
    ENDLOOP.
    PERFORM frm_display_alv TABLES gt_xy.
*  ELSEIF r_yh = 'X'."5、客户主数据-银行明细
*    FREE: gt_yh_excel,gt_yh.
*    PERFORM frm_convert_xls_to_sap TABLES gt_yh_excel.
*    LOOP AT  gt_yh_excel INTO gs_yh_excel.
*      MOVE-CORRESPONDING gs_yh_excel TO gs_yh.
*      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*        EXPORTING
*          input  = gs_yh-kunnr
*        IMPORTING
*          output = gs_yh-kunnr.
*      APPEND gs_yh TO gt_yh.
*    ENDLOOP.
*    PERFORM frm_display_alv TABLES gt_yh.
*  ELSEIF r_hb = 'X'."6、客户主数据-合作伙伴
*    FREE: gt_hb_excel,gt_hb.
*    PERFORM frm_convert_xls_to_sap TABLES gt_hb_excel.
*    LOOP AT  gt_hb_excel INTO gs_hb_excel.
*      MOVE-CORRESPONDING gs_hb_excel TO gs_hb.
*      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*        EXPORTING
*          input  = gs_hb-kunnr
*        IMPORTING
*          output = gs_hb-kunnr.
*      APPEND gs_hb TO gt_hb.
*    ENDLOOP.
*    PERFORM frm_display_alv TABLES gt_hb.
  ELSEIF r_qb = 'X'."7、客户主数据
    FREE: gt_qb_excel,gt_qb.
    PERFORM frm_convert_xls_to_sap TABLES gt_qb_excel.
    LOOP AT  gt_qb_excel INTO gs_qb_excel.
      MOVE-CORRESPONDING gs_qb_excel TO gs_qb.
      APPEND gs_qb TO gt_qb.
    ENDLOOP.
    PERFORM frm_display_alv TABLES gt_qb.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM frm_display_alv  TABLES pt_table.
  DATA:lv_ctcount TYPE char6.
  gs_layout-colwidth_optimize = 'X'."宽度自动优化
  gs_layout-zebra             = 'X'."斑马线
*  GS_LAYOUT-BOX_FIELDNAME = 'SEL'.

  REFRESH:gt_field.
  PERFORM frm_set_field .

  "&--FOR ALV_OUT
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      is_layout                = gs_layout
      it_fieldcat              = gt_field
      i_default                = 'X'
      i_save                   = 'A'
    TABLES
      t_outtab                 = pt_table
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.
FORM pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'.  "这里是定义的GUI状态名字
ENDFORM. "Set_pf_status
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.
  CASE r_ucomm.
    WHEN '&SAVE'.
      PERFORM bapi.
      IF r_jb = 'X'."1、客户主数据-基本数据
        PERFORM frm_display_alv TABLES gt_jb.
      ELSEIF r_gs = 'X'."2、客户主数据-公司代码数据
        PERFORM frm_display_alv TABLES gt_gs.
      ELSEIF r_xs = 'X'."3、客户主数据-销售视图数据
        PERFORM frm_display_alv TABLES gt_xs.
      ELSEIF r_xy = 'X'."4、客户信用主数据
        PERFORM frm_display_alv TABLES gt_xy.
*      ELSEIF r_yh = 'X'."5、客户主数据-银行明细
*        PERFORM frm_display_alv TABLES gt_yh.
*      ELSEIF r_hb = 'X'."6、客户主数据-合作伙伴
*        PERFORM frm_display_alv TABLES gt_hb.
      ELSEIF r_qb = 'X'."7、客户主数据
        PERFORM frm_display_alv TABLES gt_qb.
      ENDIF.
  ENDCASE.
ENDFORM. "ALV_USER_COMMAND
*&---------------------------------------------------------------------*
*&      Form  FRM_SET_FIELD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM frm_set_field .
  DEFINE m_alv_fieldcat.
    gs_field-fieldname = &1."字段名称
    gs_field-reptext_ddic = &2."字段描述
    gs_field-no_zero  = &3.
    gs_field-decimals_out = &4.
    APPEND gs_field TO gt_field.
    CLEAR gs_field.
  END-OF-DEFINITION.

  IF r_jb = 'X'."1、客户主数据-基本数据
    m_alv_fieldcat:
         'ICON'        '状态' '' '',
         'ZTYPE'       '消息类型' '' '',
         'ZMESSAGE'    '消息文本' '' '',
         'ZFLAG'       '更新标识' '' '',
         'KTOKD'       '客户账号组' '' '',
         'KUKLA'       '客户分类' '' '',
         'KUNNR'       '客户编号' '' '',
*         'FOUND_DAT'   '旧系统客户创建日期' '' '',
         'NAME1'       '客户名称' '' '',
         'MCOD1'       '简称' '' '',
         'MCOD2'       '简称2' '' '',
         'LAND1'       '国家' '' '',
         'REGIO'       '省' '' '',
         'ORT01'       '市' '' '',
         'COMPH'       '县/区' '' '',
         'PSTLZ'       '邮政编码' '' '',
         'SPRAS'       '语言代码' '' '',
         'NAME_CO'     '采购员' '' '',
         'TELF1'       '联系电话' '' '',
         'SMTP_ADDR'   '电子邮箱' '' '',
         'TELFX'       '传真' '' '',
         'STR'         '收货地址' '' '',
         'TAXTYPE'     '税号类别' '' '',
         'TAXNUM'      '税号' '' '',
         'WAERS'       '货币码' '' '',
         'CAP_INCR_A'  '注册资本' '' ''.
  ELSEIF r_gs = 'X'."2、客户主数据-公司代码数据
    m_alv_fieldcat:
         'ICON'        '状态' '' '',
         'ZTYPE'       '消息类型' '' '',
         'ZMESSAGE'    '消息文本' '' '',
         'ZFLAG'       '更新标识' '' '',
         'KUNNR'       '客户编号' '' '',
         'BUKRS'       '公司代码' '' '',
         'AKONT'       '统驭科目' '' '',
         'ZTERM'       '付款条件' '' '',
         'ZUAWA'       '排序码' '' ''.
*         'ALTKN'       '旧系统客户编号' '' ''.
  ELSEIF r_xs = 'X'."3、客户主数据-销售视图数据
    m_alv_fieldcat:
         'ICON'        '状态' '' '',
         'ZTYPE'       '消息类型' '' '',
         'ZMESSAGE'    '消息文本' '' '',
         'ZFLAG'       '更新标识' '' '',
         'KUNNR'       '客户编号' '' '',
         'VKORG'       '销售组织' '' '',
         'VTWEG'       '分销渠道' '' '',
         'SPART'       '产品组' '' '',
         'VKBUR'       '销售部门' '' '',
         'VKGRP'       '销售组' '' '',
         'BZIRK'       '销售区域' '' '',
         'KLABC'       '客户等级' '' '',
         'ZYWYN'       '拓展业务员' '' '',
         'WAERS'       '货币' '' '',
         'KALKS'       '客户是否含税' '' '',
         'VSBED'       '装运条件' '' '',
         'KZAZU'       '订单组合' '' '',
         'VWERK'       '交货工厂' '' '',
         'INCO1'       '国贸条件1' '' '',
         'INCO2_L'     '发运港' '' '',
         'ZTERM'       '付款条件' '' '',
         'KTGRD'       '客户科目分配组' '' '',
         'TAXKD'       '税分类' '' ''.
  ELSEIF r_xy = 'X'."4、客户信用主数据
    m_alv_fieldcat:
         'ICON'        '状态' '' '',
         'ZTYPE'       '消息类型' '' '',
         'ZMESSAGE'    '消息文本' '' '',
         'ZFLAG'              '更新标识' '' '',
         'KUNNR'              '客户编号' '' '',
         'RISK_CLASS'         '风险类' '' '',
         'LIMIT_RULE'         '计算得分和信用额度的规则' '' '',
         'CHECK_RULE'         '检查规则' '' '',
         'CREDIT_SGMNT'       '信用段' '' '',
         'CREDIT_LIMIT'       '信用额度' '' '',
         'LIMIT_VALID_DATE'   '有效终止日期' '' ''.
*  ELSEIF r_yh = 'X'."5、客户主数据-银行视图数据
*    m_alv_fieldcat:
*         'ICON'        '状态' '' '',
*         'ZTYPE'       '消息类型' '' '',
*         'ZMESSAGE'    '消息文本' '' '',
*         'ZFLAG'       '更新标识' '' '',
*         'KUNNR'       '客户编号' '' '',
*         'BKVID'       '标识' '' '',
*         'BANKS'       '国家' '' '',
*         'BANKL'       '银行代码' '' '',
*         'BANEF'       '开户账号' '' '',
*         'BANKA'       '开户银行' '' '',
*         'ACCNAME'     '开户名称' '' '',
*         'ORTAS'       '开户地址' '' '',
*         'BUT0BK'      '账户持有人' '' ''.
*  ELSEIF r_hb = 'X'."6、客户主数据-合作伙伴数据
*    m_alv_fieldcat:
*         'ICON'        '状态' '' '',
*         'ZTYPE'       '消息类型' '' '',
*         'ZMESSAGE'    '消息文本' '' '',
*         'ZFLAG'       '更新标识' '' '',
*         'KUNNR'       '客户编号' '' '',
*         'VKORG'       '销售组织' '' '',
*         'VTWEG'       '分销渠道' '' '',
*         'SPART'       '产品组' '' '',
*         'PARVW'       '合作伙伴职能' '' '',
*         'PARZA'       '合作伙伴计数器' '' '',
*         'KUNN2'       '业务伙伴的客户号' '' '',
*         'KNREF'       '描述' '' ''.
  ELSEIF r_qb = 'X'."7、客户主数据
    m_alv_fieldcat:
         'ICON'        '状态' '' '',
         'ZTYPE'       '消息类型' '' '',
         'ZMESSAGE'    '消息文本' '' '',
         'ZFLAG'       '更新标识' '' '',
         'KTOKD'       '客户账号组' '' '',
         'KUKLA'       '客户分类' '' '',
         'KUNNR'       '客户编号' '' '',
*         'FOUND_DAT'   '旧系统客户创建日期' '' '',
         'NAME1'       '客户名称' '' '',
         'MCOD1'       '简称' '' '',
         'MCOD2'       '简称2' '' '',
         'LAND1'       '国家' '' '',
         'REGIO'       '省' '' '',
         'ORT01'       '市' '' '',
         'COMPH'       '县/区' '' '',
         'PSTLZ'       '邮政编码' '' '',
         'SPRAS'       '语言代码' '' '',
         'NAME_CO'     '采购员' '' '',
         'TELF1'       '联系电话' '' '',
         'SMTP_ADDR'   '电子邮箱' '' '',
         'TELFX'       '传真' '' '',
         'STR'         '收货地址' '' '',
         'TAXTYPE'     '税号类别' '' '',
         'TAXNUM'      '税号' '' '',
         'WAERS'       '货币码' '' '',
         'CAP_INCR_A'  '注册资本' '' '',
         'BUKRS'       '公司代码' '' '',
         'AKONT'       '统驭科目' '' '',
         'ZTERM'       '付款条件' '' '',
         'ZUAWA'       '排序码' '' '',
*         'ALTKN'       '旧系统客户编号' '' '',
         'VKORG'       '销售组织' '' '',
         'VTWEG'       '分销渠道' '' '',
         'SPART'       '产品组' '' '',
         'VKBUR'       '销售部门' '' '',
         'VKGRP'       '销售组' '' '',
         'BZIRK'       '销售区域' '' '',
         'KLABC'       '客户等级' '' '',
         'ZYWYN'       '拓展业务员' '' '',
         'WAERS1'      '货币' '' '',
         'KALKS'       '客户是否含税' '' '',
         'VSBED'       '装运条件' '' '',
         'KZAZU'       '订单组合' '' '',
         'VWERK'       '交货工厂' '' '',
         'INCO1'       '国贸条件1' '' '',
         'INCO2_L'     '发运港' '' '',
         'ZTERM'       '付款条件' '' '',
         'KTGRD'       '客户科目分配组' '' '',
         'TAXKD'       '税分类' '' '',
         'RISK_CLASS'         '风险类' '' '',
         'LIMIT_RULE'         '计算得分和信用额度的规则' '' '',
         'CHECK_RULE'         '检查规则' '' '',
         'CREDIT_SGMNT'       '信用段' '' '',
         'CREDIT_LIMIT'       '信用额度' '' '',
         'LIMIT_VALID_DATE'   '有效终止日期' '' ''.
*         'BKVID'       '标识' '' '',
*         'BANKS'       '国家' '' '',
*         'BANKL'       '银行代码' '' '',
*         'BANEF'       '开户账号' '' '',
*         'BANKA'       '开户银行' '' '',
*         'ACCNAME'     '开户名称' '' '',
*         'ORTAS'       '开户地址' '' '',
*         'BUT0BK'      '账户持有人' '' ''.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1      text
*----------------------------------------------------------------------*
FORM get_file  USING itype.
  DATA: rc TYPE i.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    CHANGING
      file_table = gt_filename[]
      rc         = rc.
  IF sy-subrc = 0.
    READ TABLE gt_filename INDEX 1.
    p_file = gt_filename-filename.
  ENDIF.
ENDFORM.
**&---------------------------------------------------------------------*
**&      Form  FRM_CHECK_INPUT_DATA
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
FORM frm_check_input_data .
  IF p_file IS INITIAL.
    MESSAGE s001(00) WITH '请输入上载文件路径' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_CONVERT_XLS_TO_SAP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TABLE  text
*----------------------------------------------------------------------*
FORM frm_convert_xls_to_sap  TABLES p_table .

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
      i_line_header        = 'X' "表示有表头
      i_tab_raw_data       = gt_raw
      i_filename           = p_file
    TABLES
      i_tab_converted_data = p_table[]
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form bapi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM bapi .
  DATA:ls_data   TYPE zssd001.
  DATA:ls_data1  TYPE zssd001.
  DATA:lv_status TYPE string.
  DATA:lv_msg    TYPE string.
  DATA:lv_kunnr  TYPE zssd001_basic-kunnr.
  DATA: zt_basic_data  TYPE TABLE OF zssd001_basic WITH HEADER LINE,  "客户主数据-基本数据
        zt_basic_data1 TYPE TABLE OF zssd001_basic ,  "
        zt_fi_data     TYPE TABLE OF zssd001_fi WITH HEADER LINE,      "客户主数据-公司代码
        zt_sales_data  TYPE TABLE OF zssd001_sales WITH HEADER LINE,   "客户主数据-销售与分销
*        zt_parvw_data  TYPE TABLE OF zssd001_parvw WITH HEADER LINE,   "客户主数据-合作伙伴
*        zt_knbk_data   TYPE TABLE OF zssd001_knbk WITH HEADER LINE,    "客户主数据-银行明细
        zt_ukm_data    TYPE TABLE OF zssd001_ukm WITH HEADER LINE.     "客户主数据-客户信用明细
  DATA:ls_zdata TYPE zssd001_basic.

  IF r_jb = 'X'."1、客户主数据-基本数据.

    LOOP AT gt_jb INTO gs_jb.

      CLEAR:zt_basic_data,zt_basic_data[],ls_data.
      zt_basic_data-zflag      = gs_jb-zflag.
      zt_basic_data-ktokd      = gs_jb-ktokd.
      zt_basic_data-kukla      = gs_jb-kukla.
      zt_basic_data-kunnr      = gs_jb-kunnr.
*      zt_basic_data-found_dat  = gs_jb-found_dat.
      zt_basic_data-name1      = gs_jb-name1.
      zt_basic_data-mcod1      = gs_jb-mcod1.
      zt_basic_data-mcod2      = gs_jb-mcod2.
      zt_basic_data-land1      = gs_jb-land1.
      zt_basic_data-regio      = gs_jb-regio.
      zt_basic_data-ort01      = gs_jb-ort01.
      zt_basic_data-comph      = gs_jb-comph.
      zt_basic_data-pstlz      = gs_jb-pstlz.
      zt_basic_data-spras      = gs_jb-spras.
      zt_basic_data-name_co    = gs_jb-name_co.
      zt_basic_data-telf1      = gs_jb-telf1.
      zt_basic_data-smtp_addr  = gs_jb-smtp_addr.
      zt_basic_data-telfx      = gs_jb-telfx.
      zt_basic_data-street     = gs_jb-str+0(60).
      zt_basic_data-str_suppl1 = gs_jb-str+60(40).
      zt_basic_data-str_suppl2 = gs_jb-str+100(40).
      zt_basic_data-taxtype    = gs_jb-taxtype.
      zt_basic_data-taxnum     = gs_jb-taxnum.
      zt_basic_data-waers      = gs_jb-waers.
      zt_basic_data-cap_incr_a = gs_jb-cap_incr_a.
      APPEND zt_basic_data.

      ls_data-zbasic = 'X'.
      ls_data-zt_basic_data    = zt_basic_data[].
      CALL FUNCTION 'ZFM_SD001'
        EXPORTING
          fs_sdjfh = ls_data
        IMPORTING
          status   = lv_status
          msg      = lv_msg.

      IF lv_status = 'E'.
        gs_qb-icon = icon_red_light.
        lv_msg = '基本视图创建失败：' && lv_msg.
      ELSE.
        gs_qb-icon = icon_green_light.
        "反序列json解析
        /ui2/cl_json=>deserialize( EXPORTING json = lv_msg
                                    CHANGING  data = ls_data1 ).
        zt_basic_data1[] = ls_data1-zt_basic_data.
        READ TABLE zt_basic_data1 INTO ls_zdata INDEX 1.
        lv_kunnr = ls_zdata-kunnr.
        lv_msg = '基本视图创建成功！客户编号为：' && lv_kunnr.
      ENDIF.
      gs_jb-ztype    = lv_status.
      gs_jb-zmessage = lv_msg.
      gs_jb-kunnr    = lv_kunnr.
      MODIFY gt_jb FROM gs_jb TRANSPORTING kunnr icon ztype zmessage.
    ENDLOOP.

  ELSEIF r_gs = 'X'."2、客户主数据-公司代码数据

    LOOP AT gt_gs INTO gs_kgs.
      CLEAR:zt_fi_data,zt_fi_data[],ls_data.
      zt_fi_data-zflag = gs_kgs-zflag.
      zt_fi_data-kunnr = gs_kgs-kunnr.
      zt_fi_data-bukrs = gs_kgs-bukrs.
      zt_fi_data-akont = gs_kgs-akont.
      zt_fi_data-zterm = gs_kgs-zterm.
      zt_fi_data-zuawa = gs_kgs-zuawa.
*      zt_fi_data-altkn = gs_kgs-altkn.
      APPEND zt_fi_data.

      ls_data-zfi = 'X'.
      ls_data-zt_fi_data    = zt_fi_data[].
      CALL FUNCTION 'ZFM_SD001'
        EXPORTING
*         FD_DATA  =
          fs_sdjfh = ls_data
        IMPORTING
          status   = lv_status
          msg      = lv_msg.

      IF lv_status = 'E'.
        gs_qb-icon = icon_red_light.
        lv_msg = '公司代码创建失败：' && lv_msg.
      ELSE.
        gs_qb-icon = icon_green_light.
        lv_msg     = '公司代码创建成功！'.
      ENDIF.
      gs_kgs-ztype    = lv_status.
      gs_kgs-zmessage = lv_msg.
      MODIFY gt_gs FROM gs_kgs TRANSPORTING icon ztype zmessage.
    ENDLOOP.


  ELSEIF r_xs = 'X'."3、客户主数据-销售视图数据

    LOOP AT gt_xs INTO gs_xs.
      CLEAR:zt_sales_data,zt_sales_data[],ls_data.
      zt_sales_data-zflag   = gs_xs-zflag.
      zt_sales_data-kunnr   = gs_xs-kunnr.
      zt_sales_data-vkorg   = gs_xs-vkorg.
      zt_sales_data-vtweg   = gs_xs-vtweg.
      zt_sales_data-spart   = gs_xs-spart.
      zt_sales_data-vkbur   = gs_xs-vkbur.
      zt_sales_data-vkgrp   = gs_xs-vkgrp.
      zt_sales_data-bzirk   = gs_xs-bzirk.
      zt_sales_data-klabc   = gs_xs-klabc.
      zt_sales_data-zywyn   = gs_xs-zywyn.
      zt_sales_data-waers   = gs_xs-waers.
      zt_sales_data-kalks   = gs_xs-kalks.
      zt_sales_data-vsbed   = gs_xs-vsbed.
      zt_sales_data-kzazu   = gs_xs-kzazu.
      zt_sales_data-vwerk   = gs_xs-vwerk.
      zt_sales_data-inco1   = gs_xs-inco1.
      zt_sales_data-inco2_l = gs_xs-inco2_l.
      zt_sales_data-zterm   = gs_xs-zterm.
      zt_sales_data-ktgrd   = gs_xs-ktgrd.
      zt_sales_data-taxkd   = gs_xs-taxkd.
      APPEND zt_sales_data.

      ls_data-zsales = 'X'.
      ls_data-zt_sales_data    = zt_sales_data[].
      CALL FUNCTION 'ZFM_SD001'
        EXPORTING
*         FD_DATA  =
          fs_sdjfh = ls_data
        IMPORTING
          status   = lv_status
          msg      = lv_msg.

      IF lv_status = 'E'.
        gs_qb-icon = icon_red_light.
        lv_msg = '销售视图创建失败：' && lv_msg.
      ELSE.
        gs_qb-icon = icon_green_light.
        lv_msg = '销售视图创建成功!'.
      ENDIF.
      gs_xs-ztype    = lv_status.
      gs_xs-zmessage = lv_msg.
      MODIFY gt_xs FROM gs_xs TRANSPORTING icon ztype zmessage.
    ENDLOOP.

  ELSEIF r_xy = 'X'."4、客户信用主数据

    LOOP AT gt_xy INTO gs_xy.
      CLEAR:zt_ukm_data,zt_ukm_data[],ls_data.
      zt_ukm_data-zflag            = gs_xy-zflag.
      zt_ukm_data-kunnr            = gs_xy-kunnr.
      zt_ukm_data-risk_class       = gs_xy-risk_class.
      zt_ukm_data-limit_rule       = gs_xy-limit_rule.
      zt_ukm_data-check_rule       = gs_xy-check_rule.
      zt_ukm_data-credit_sgmnt     = gs_xy-credit_sgmnt.
      zt_ukm_data-credit_limit     = gs_xy-credit_limit.
      zt_ukm_data-limit_valid_date = gs_xy-limit_valid_date.
      APPEND zt_ukm_data.

      ls_data-zukm = 'X'.
      ls_data-zt_ukm_data    = zt_ukm_data[].
      CALL FUNCTION 'ZFM_SD001'
        EXPORTING
*         FD_DATA  =
          fs_sdjfh = ls_data
        IMPORTING
          status   = lv_status
          msg      = lv_msg.

      IF lv_status = 'E'.
        gs_qb-icon = icon_red_light.
        lv_msg = '信用段创建失败：' && lv_msg.
      ELSE.
        gs_qb-icon = icon_green_light.
        lv_msg = '信用段创建成功！'.
      ENDIF.
      gs_xy-ztype    = lv_status.
      gs_xy-zmessage = lv_msg.
      MODIFY gt_xy FROM gs_xy TRANSPORTING icon ztype zmessage.
    ENDLOOP.

*  ELSEIF r_yh = 'X'."5、客户银行主数据
*
*    LOOP AT gt_yh INTO gs_yh.
*      CLEAR:zt_knbk_data,zt_knbk_data[],ls_data.
*      zt_knbk_data-zflag   = gs_yh-zflag.
*      zt_knbk_data-kunnr   = gs_yh-kunnr.
*      zt_knbk_data-bkvid   = gs_yh-bkvid.
*      zt_knbk_data-banks   = gs_yh-banks.
*      zt_knbk_data-bankl   = gs_yh-bankl.
*      zt_knbk_data-bankn   = gs_yh-banef+0(18).
*      zt_knbk_data-bkref   = gs_yh-banef+18(20).
*      zt_knbk_data-banka   = gs_yh-banka.
*      zt_knbk_data-accname = gs_yh-accname.
*      zt_knbk_data-ort01   = gs_yh-ortas+0(35).
*      zt_knbk_data-stras   = gs_yh-ortas+35(35).
*      zt_knbk_data-but0bk  = gs_yh-but0bk.
*      APPEND zt_knbk_data.
*
*      ls_data-zknbk = 'X'.
*      ls_data-zt_knbk_data    = zt_knbk_data[].
*      CALL FUNCTION 'ZFM_SD001'
*        EXPORTING
**         FD_DATA  =
*          fs_sdjfh = ls_data
*        IMPORTING
*          status   = lv_status
*          msg      = lv_msg.
*
*      IF lv_status = 'E'.
*        gs_qb-icon = icon_red_light.
*        lv_msg = '银行视图创建失败：' && lv_msg.
*      ELSE.
*        gs_qb-icon = icon_green_light.
*        lv_msg = '银行视图创建成功!'.
*      ENDIF.
*      gs_yh-ztype    = lv_status.
*      gs_yh-zmessage = lv_msg.
*      MODIFY gt_yh FROM gs_yh TRANSPORTING icon ztype zmessage.
*    ENDLOOP.
*
*  ELSEIF r_hb = 'X'."6、客户主数据-合作伙伴
*
*    LOOP AT gt_hb INTO gs_hb.
*      CLEAR:zt_parvw_data,zt_parvw_data[],ls_data.
*      zt_parvw_data-zflag = gs_hb-zflag.
*      zt_parvw_data-kunnr = gs_hb-kunnr.
*      zt_parvw_data-vkorg = gs_hb-vkorg.
*      zt_parvw_data-vtweg = gs_hb-vtweg.
*      zt_parvw_data-spart = gs_hb-spart.
*      zt_parvw_data-parvw = gs_hb-parvw.
*      zt_parvw_data-parza = gs_hb-parza.
*      zt_parvw_data-kunn2 = gs_hb-kunn2.
*      zt_parvw_data-knref = gs_hb-knref.
*      APPEND zt_parvw_data.
*
*      ls_data-zparvw = 'X'.
*      ls_data-zt_parvw_data    = zt_parvw_data[].
*      CALL FUNCTION 'ZFM_SD001'
*        EXPORTING
**         FD_DATA  =
*          fs_sdjfh = ls_data
*        IMPORTING
*          status   = lv_status
*          msg      = lv_msg.
*
*      IF lv_status = 'E'.
*        gs_hb-icon = icon_red_light.
*        lv_msg = '合作伙伴创建失败：' && lv_msg.
*      ELSE.
*        gs_hb-icon = icon_green_light.
*        lv_msg = '合作伙伴创建成功!'.
*      ENDIF.
*      gs_hb-ztype    = lv_status.
*      gs_hb-zmessage = lv_msg.
*      MODIFY gt_hb FROM gs_hb TRANSPORTING icon ztype zmessage.
*    ENDLOOP.

  ELSEIF r_qb = 'X'."7、客户主数据

    LOOP AT gt_qb INTO gs_qb.
*&------------------------------------------------------------------
      "1、客户主数据-基本数据.
      CLEAR:zt_basic_data,zt_basic_data[].
      CLEAR:ls_data.
      zt_basic_data-zflag      = gs_qb-zflag.
      zt_basic_data-ktokd      = gs_qb-ktokd.
      zt_basic_data-kukla      = gs_qb-kukla.
      zt_basic_data-kunnr      = gs_qb-kunnr.
*      zt_basic_data-found_dat  = gs_qb-found_dat.
      zt_basic_data-name1      = gs_qb-name1.
      zt_basic_data-mcod1      = gs_qb-mcod1.
      zt_basic_data-mcod2      = gs_qb-mcod2.
      zt_basic_data-land1      = gs_qb-land1.
      zt_basic_data-regio      = gs_qb-regio.
      zt_basic_data-ort01      = gs_qb-ort01.
      zt_basic_data-comph      = gs_qb-comph.
      zt_basic_data-pstlz      = gs_qb-pstlz.
      zt_basic_data-spras      = gs_qb-spras.
      zt_basic_data-name_co    = gs_qb-name_co.
      zt_basic_data-telf1      = gs_qb-telf1.
      zt_basic_data-smtp_addr  = gs_qb-smtp_addr.
      zt_basic_data-telfx      = gs_qb-telfx.
      zt_basic_data-street     = gs_qb-str+0(60).
      zt_basic_data-str_suppl1 = gs_qb-str+60(40).
      zt_basic_data-str_suppl2 = gs_qb-str+100(40).
      zt_basic_data-taxtype    = gs_qb-taxtype.
      zt_basic_data-taxnum     = gs_qb-taxnum.
      zt_basic_data-waers      = gs_qb-waers.
      zt_basic_data-cap_incr_a = gs_qb-cap_incr_a.
      APPEND zt_basic_data.

      ls_data-zbasic = 'X'.
      ls_data-zt_basic_data    = zt_basic_data[].
      CALL FUNCTION 'ZFM_SD001'
        EXPORTING
          fs_sdjfh = ls_data
        IMPORTING
          status   = lv_status
          msg      = lv_msg.
      IF lv_status = 'E'.
        gs_qb-icon = icon_red_light.
      ELSE.
        gs_qb-icon = icon_green_light.
        "反序列json解析
        /ui2/cl_json=>deserialize( EXPORTING json = lv_msg
                                    CHANGING  data = ls_data1 ).
        zt_basic_data1[] = ls_data1-zt_basic_data.
        READ TABLE zt_basic_data1 INTO ls_zdata INDEX 1.
        lv_kunnr = ls_zdata-kunnr.
        READ TABLE zt_basic_data1 INTO ls_zdata INDEX 1.
        lv_msg = ls_zdata-zmessage.
      ENDIF.
      gs_qb-ztype    = lv_status.
      gs_qb-zmessage = lv_msg.
      gs_qb-kunnr    = lv_kunnr.
*&------------------------------------------------------------------
      "2、客户主数据-公司代码数据
      IF gs_qb-ztype = 'S'.
        CLEAR:gs_kgs,zt_fi_data,zt_fi_data[].
        CLEAR:ls_data.
        zt_fi_data-zflag = gs_qb-zflag.
        zt_fi_data-kunnr = lv_kunnr.
        zt_fi_data-bukrs = gs_qb-bukrs.
        zt_fi_data-akont = gs_qb-akont.
        zt_fi_data-zterm = gs_qb-zterm.
        zt_fi_data-zuawa = gs_qb-zuawa.
*        zt_fi_data-altkn = gs_qb-altkn.
        APPEND zt_fi_data.

        ls_data-zfi = 'X'   .
        ls_data-zt_fi_data    = zt_fi_data[].
        CALL FUNCTION 'ZFM_SD001'
          EXPORTING
            fs_sdjfh = ls_data
          IMPORTING
            status   = lv_status
            msg      = lv_msg.
        IF lv_status = 'E'.
          gs_qb-icon = icon_red_light.
        ELSE.
          gs_qb-icon = icon_green_light.
          lv_msg     = '公司代码创建成功'.
        ENDIF.
        gs_qb-ztype    = lv_status.
        CONCATENATE gs_qb-zmessage '/' lv_msg INTO gs_qb-zmessage.
      ENDIF.
*&------------------------------------------------------------------
      "3、客户主数据-销售视图数据
*检查权限
      IF gs_qb-ztype = 'S'.
        AUTHORITY-CHECK OBJECT 'V_KNA1_VKO'
         ID 'SPART' FIELD gs_qb-spart
         ID 'VKORG' FIELD gs_qb-vkorg
         ID 'VTWEG' FIELD gs_qb-vtweg
         ID 'ACTVT' FIELD '02'.
        IF sy-subrc NE 0.
          gs_qb-icon = icon_red_light.
          gs_qb-ztype = 'E'.
          gs_qb-zmessage = '销售视图权限不足，请检查权限！'.
          MODIFY gt_qb FROM gs_qb TRANSPORTING icon ztype zmessage.
          CONTINUE.
        ENDIF.
        CLEAR:gs_xs,zt_sales_data,zt_sales_data[].
        CLEAR:ls_data.
        zt_sales_data-zflag   = gs_qb-zflag.
        zt_sales_data-kunnr   = lv_kunnr.
        zt_sales_data-vkorg   = gs_qb-vkorg.
        zt_sales_data-vtweg   = gs_qb-vtweg.
        zt_sales_data-spart   = gs_qb-spart.
        zt_sales_data-vkbur   = gs_qb-vkbur.
        zt_sales_data-vkgrp   = gs_qb-vkgrp.
        zt_sales_data-bzirk   = gs_xs-bzirk.
        zt_sales_data-klabc   = gs_xs-klabc.
        zt_sales_data-zywyn   = gs_xs-zywyn.
        zt_sales_data-waers   = gs_qb-waers1.
        zt_sales_data-kalks   = gs_qb-kalks.
        zt_sales_data-vsbed   = gs_qb-vsbed.
        zt_sales_data-kzazu   = gs_qb-kzazu.
        zt_sales_data-vwerk   = gs_qb-vwerk.
        zt_sales_data-inco1   = gs_qb-inco1.
        zt_sales_data-inco2_l = gs_qb-inco2_l.
        zt_sales_data-zterm   = gs_qb-zterm1.
        zt_sales_data-ktgrd   = gs_qb-ktgrd.
        zt_sales_data-taxkd   = gs_qb-taxkd.
        APPEND zt_sales_data.

        ls_data-zsales = 'X'.
        ls_data-zt_sales_data    = zt_sales_data[].
        CALL FUNCTION 'ZFM_SD001'
          EXPORTING
            fs_sdjfh = ls_data
          IMPORTING
            status   = lv_status
            msg      = lv_msg.
        IF lv_status = 'E'.
          gs_qb-icon = icon_red_light.
        ELSE.
          gs_qb-icon = icon_green_light.
          lv_msg = '销售视图创建成功'.
        ENDIF.

        gs_qb-ztype    = lv_status.
        CONCATENATE gs_qb-zmessage '/' lv_msg INTO gs_qb-zmessage.
      ENDIF.
*&------------------------------------------------------------------
*      "4、客户信用主数据
*      IF gs_qb-ztype = 'S'.
*        CLEAR:gs_xy,zt_ukm_data,zt_ukm_data[].
*        CLEAR:ls_data.
*        zt_ukm_data-zflag            = gs_qb-zflag.
*        zt_ukm_data-kunnr            = lv_kunnr.
*        zt_ukm_data-risk_class       = gs_qb-risk_class.
*        zt_ukm_data-limit_rule       = gs_qb-limit_rule.
*        zt_ukm_data-check_rule       = gs_qb-check_rule.
*        zt_ukm_data-credit_sgmnt     = gs_qb-credit_sgmnt.
*        zt_ukm_data-credit_limit     = gs_qb-credit_limit.
*        zt_ukm_data-limit_valid_date = gs_qb-limit_valid_date.
*        APPEND zt_ukm_data.
*
*        ls_data-zukm = 'X'  .
*        ls_data-zt_ukm_data    = zt_ukm_data[].
*        CALL FUNCTION 'ZFM_SD001'
*          EXPORTING
**           FD_DATA  =
*            fs_sdjfh = ls_data
*          IMPORTING
*            status   = lv_status
*            msg      = lv_msg.
*        IF lv_status = 'E'.
*          gs_qb-icon = icon_red_light.
*        ELSE.
*          gs_qb-icon = icon_green_light.
*          lv_msg = '信用段创建成功'.
*        ENDIF.
*        gs_qb-ztype    = lv_status.
*        CONCATENATE gs_qb-zmessage '/' lv_msg INTO gs_qb-zmessage.
*      ENDIF.
*&------------------------------------------------------------------
*      "5、客户银行主数据
*      IF gs_qb-ztype = 'S'.
*        CLEAR:gs_yh,zt_knbk_data,zt_knbk_data[].
*        CLEAR:ls_data.
*        zt_knbk_data-zflag   = gs_qb-zflag.
*        zt_knbk_data-kunnr   = lv_kunnr.
*        zt_knbk_data-bkvid   = gs_qb-bkvid.
*        zt_knbk_data-banks   = gs_qb-banks.
*        zt_knbk_data-bankl   = gs_qb-bankl.
*        zt_knbk_data-bankn   = gs_qb-banef+0(18).
*        zt_knbk_data-bkref   = gs_qb-banef+18(20).
*        zt_knbk_data-banka   = gs_qb-banka.
*        zt_knbk_data-accname = gs_qb-accname.
*        zt_knbk_data-ort01   = gs_qb-ortas+0(35).
*        zt_knbk_data-stras   = gs_qb-ortas+35(35).
*        zt_knbk_data-but0bk  = gs_qb-but0bk.
*        APPEND zt_knbk_data.
*
*        ls_data-zknbk = 'X' .
*        ls_data-zt_knbk_data    = zt_knbk_data[].
*        CALL FUNCTION 'ZFM_SD001'
*          EXPORTING
*            fs_sdjfh = ls_data
*          IMPORTING
*            status   = lv_status
*            msg      = lv_msg.
*        IF lv_status = 'E'.
*          gs_qb-icon = icon_red_light.
*        ELSE.
*          gs_qb-icon = icon_green_light.
*          lv_msg = '银行视图创建成功'.
*        ENDIF.
*
*        gs_qb-ztype    = lv_status.
*        CONCATENATE gs_qb-zmessage '/' lv_msg INTO gs_qb-zmessage.
*      ENDIF.
      MODIFY gt_qb FROM gs_qb TRANSPORTING kunnr icon ztype zmessage.
    ENDLOOP.
  ENDIF.
ENDFORM.
