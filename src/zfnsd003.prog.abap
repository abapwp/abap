*&---------------------------------------------------------------------*
*& REPORT ZFNSD003
*&---------------------------------------------------------------------*
***& TITLE         :  出货明细报表                ***
***& MODULE NAME   :  SD                        ***
***& SUB-MODULE    :                         ***
***& AUTHOR        :  ITL                      ***
***& CREATE DATE   :  2022-08-30                  ***
***& LOGICAL DB    :  NOTHING                     ***
***& PROGRAM TYPE   : FN                                ***
***&---------------------------------------------------------------------***
*& REVISION LOG                                                        *
*& LOG#     DATE       AUTHOR        DESCRIPTION                       *
*& ----     ----       ----------    -----------                       *
*& 0000  2022-08-30   ITL           CREATE                          *
*&---------------------------------------------------------------------*
REPORT zfnsd003.

"表声明
TABLES:likp,adrc,bp001,knvv,lips,mara,kna1,adr6,sscrfields.


"表定义
DATA:BEGIN OF gs_data,
       vbeln     TYPE  likp-vbeln     , "SAP出货单号
       posnr     TYPE  lips-posnr     , "SAP出货行号
       zwlgs     TYPE  likp-zwlgs     , "物流公司
       zkddh     TYPE  likp-zkddh     , "快递单号
       bukrs     TYPE  vbak-bukrs_vf  , "销售公司
       butxt     TYPE  t001-butxt     , "销售公司名称
       vtweg     TYPE  vbak-vtweg     , "分销渠道
       vtext     TYPE  tvtwt-vtext    , "分销渠道名称
       lfart     TYPE  likp-lfart     , "出货类型
       zvtext    TYPE  tvlkt-vtext    , "订单类型名称
       wadat     TYPE  likp-wadat     , "计划交货日期
       wadat_ist TYPE  likp-wadat_ist , "实际出货日期
       zdpmc     TYPE  likp-zdpmc     , "店铺/客户名称
       bzirk     TYPE  likp-bzirk     , "销售地区
       vkbur     TYPE  likp-vkbur     , "销售部门（一级）
       vkgrp     TYPE  vbak-vkgrp     , "销售部门（二级）
       land1     TYPE  adrc-country   , "国家
       region    TYPE  adrc-region    , "省
       mc_city1  TYPE  adrc-mc_city1  , "市
       comp_head TYPE  bp001-comp_head, "区/县
       zywy      TYPE  vbak-zywy      , "业务员
       zwbxtbs   TYPE  lips-zwbxtbs   , "平台交易单号
       matnr     TYPE  lips-matnr     , "产品代号/物料编码
       maktx     TYPE  makt-maktx     , "产品名称/物料名称
       zcpxh     TYPE  lips-zcpxh     , "产品类型
       lfimg     TYPE  lips-lfimg     , "计划交货数量
       rfmng     TYPE  vbfa-rfmng     , "实际交货数量
       werks     TYPE  lips-werks     , "出货工厂
       lgort     TYPE  lips-lgort     , "出货仓库
       zkzwi1    TYPE  vbap-kzwi2     , "VBAP-KZWI2/ VBAP- KWMENG  折前单价
       kzwi2     TYPE  vbap-kzwi2     , "折前金额
       kzwi4     TYPE  vbap-kzwi4     , "促销折扣
       kzwi6     TYPE  vbap-kzwi6     , "其他折扣
       kzwi1     TYPE  vbap-kzwi1     , "折后金额
       zkzwi2    TYPE  vbap-kzwi1     , "VBAP-KZWI1/ VBAP- KWMENG  折后单价
       zbstnk    TYPE  likp-zbstnk    , "OMS订单号
       smtp_addr TYPE  adr6-smtp_addr , "客户邮箱
       kukla     TYPE  kna1-kukla     , "客户分类
       zkhdj     TYPE  vbak-zkhdj     , "客户等级
       waerk     TYPE  vbap-waerk     , "币种
       cmkua     TYPE  vbap-cmkua     , "汇率

       kwmeng    TYPE vbap-kwmeng,
     END OF gs_data.

DATA:gt_data LIKE TABLE OF gs_data.

FIELD-SYMBOLS:<fs_data> LIKE gs_data.

"ALV展示用的变量
DATA: gt_fieldcat TYPE lvc_t_fcat,        "存放字段目录的内表 FIELDCAT
      gs_fieldcat LIKE LINE OF gt_fieldcat,
      gs_layout   TYPE lvc_s_layo,        "布局结构 LAYOUT
      gs_setting  TYPE lvc_s_glay,        "设置
      gt_event    TYPE slis_t_event.

"选择界面
SELECTION-SCREEN BEGIN OF BLOCK bk1.
  SELECT-OPTIONS:s_wadat   FOR likp-wadat_ist,"实际出货日期
                 s_kunnr   FOR likp-kunnr,    "客户号
                 s_land1   FOR adrc-country,  "国家
                 s_region  FOR adrc-region,    "省
                 s_city    FOR adrc-mc_city1,"市
                 s_comp    FOR bp001-comp_head, "区/县
                 s_bzirk   FOR knvv-bzirk, "销售地区
                 s_vkorg   FOR knvv-vkorg,  "销售组织
                 s_vtweg   FOR knvv-vtweg,  "分销渠道
                 s_vkbur   FOR knvv-vkbur,  "销售部门（一级）
                 s_vkgrp   FOR knvv-vkgrp,  "销售部门（二级）
                 s_zcpxh   FOR lips-zcpxh,  "产品型号（SPU）
                 s_matnr   FOR mara-matnr,  "产品代号（SKU）
                 s_klabc   FOR knvv-klabc,  "客户等级
                 s_kukla   FOR kna1-kukla,  "客户分类
                 s_lfart   FOR likp-lfart, "出货类型
                 s_zbstnk  FOR likp-zbstnk,  "OMS订单号
                 s_zwbxt   FOR lips-zwbxtbs, "平台交易单号
                 s_smtp   FOR adr6-smtp_addr ,  "客户邮箱
                 s_zwlgs FOR  likp-zwlgs, "物流公司
                 s_zkddh FOR  likp-zkddh, "快递单号
                 s_werks FOR  lips-werks. "出货仓库
SELECTION-SCREEN END OF BLOCK bk1.


*&---------------------------------------------------------------------*
*& 取数逻辑
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM frm_get_data.

*&---------------------------------------------------------------------*
*& 设置ALV字段&布局变量，调用ALV展示
*&---------------------------------------------------------------------*
  PERFORM frm_build_field CHANGING gt_fieldcat.             "定义列标题信息
  PERFORM frm_build_layout CHANGING gs_layout.              "定义ALV格式属性
  PERFORM frm_display_data_alv TABLES gt_data             "显示数据
                                 CHANGING gt_fieldcat
                                          gs_layout
                                          gs_setting.

END-OF-SELECTION.
*&---------------------------------------------------------------------*
*& Form frm_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_get_data .
  SELECT likp~vbeln     , "SAP出货单号
         lips~posnr     , "SAP出货行号
         likp~zwlgs     , "物流公司
         likp~zkddh     , "快递单号
         vbak~bukrs_vf AS bukrs , "销售公司
         t001~butxt     , "销售公司名称
         vbak~vtweg     , "分销渠道
         tvtwt~vtext    , "分销渠道名称
         likp~lfart     , "出货类型
         tvlkt~vtext AS zvtext   , "订单类型名称
         likp~wadat     , "计划交货日期
         likp~wadat_ist , "实际出货日期
         likp~zdpmc     , "店铺/客户名称
         likp~bzirk     , "销售地区
         likp~vkbur     , "销售部门（一级）
         vbak~vkgrp     , "销售部门（二级）
         adrc~country  AS land1 , " 国家
         adrc~region    , "  省
         adrc~mc_city1  , "市
         bp001~comp_head, " 区/县
         vbak~zywy      , "业务员
         lips~zwbxtbs   , "平台交易单号
         lips~matnr     , "产品代号/物料编码
         makt~maktx     , "产品名称/物料名称
         lips~zcpxh     , "产品类型
         lips~lfimg     , "计划交货数量
*         vbfa~rfmng     , "实际交货数量
         lips~werks     , "出货工厂
         lips~lgort     , "出货仓库
         vbap~kzwi2     , "折前金额
         vbap~kzwi4     , "促销折扣
         vbap~kzwi6     , "其他折扣
         vbap~kzwi1     , "折后金额
         likp~zbstnk    , "  OMS订单号
         adr6~smtp_addr , " 客户邮箱
         kna1~kukla     , "客户分类
         vbak~zkhdj     , "客户等级
         vbap~waerk     , "币种
         vbap~cmkua     , "汇率
         vbap~kwmeng
    FROM likp
    INNER JOIN lips ON likp~vbeln = lips~vbeln
    INNER JOIN vbap ON lips~vgbel = vbap~vbeln AND lips~vgpos = vbap~posnr
    INNER JOIN vbak ON vbap~vbeln = vbak~vbeln
    INNER JOIN kna1 ON likp~kunnr = kna1~kunnr
    LEFT JOIN t001 ON vbak~bukrs_vf = t001~bukrs AND t001~spras = @sy-langu
    LEFT JOIN tvtwt ON vbak~vtweg = tvtwt~vtweg AND tvtwt~spras = @sy-langu
    LEFT JOIN tvlkt ON likp~lfart = tvlkt~lfart AND tvlkt~spras = @sy-langu
    LEFT JOIN makt ON lips~matnr = makt~matnr AND makt~spras = @sy-langu
    LEFT JOIN adrc ON kna1~adrnr = adrc~addrnumber
    LEFT JOIN adr6 ON kna1~adrnr = adr6~addrnumber
    LEFT JOIN bp001 ON kna1~kunnr = bp001~partner
*    LEFT JOIN vbfa ON vbfa~vbelv = lips~vbeln AND vbfa~posnv = lips~posnr
*    and VBTYP_N = 'Q' AND vbfa~VBTYP_V = 'J'
    INTO CORRESPONDING FIELDS OF TABLE @gt_data
    WHERE likp~wadat_ist  IN @s_wadat
      AND likp~kunnr      IN @s_kunnr
      AND adrc~country    IN @s_land1
      AND adrc~region     IN @s_region
      AND adrc~mc_city1   IN @s_city
      AND bp001~comp_head IN @s_comp
      AND likp~bzirk IN @s_bzirk
      AND likp~vkorg IN @s_vkorg
      AND vbak~vtweg IN @s_vtweg
      AND likp~vkbur IN @s_vkbur
      AND vbak~vkgrp IN @s_vkgrp
      AND lips~zcpxh IN @s_zcpxh
      AND lips~matnr IN @s_matnr
      AND vbak~zkhdj IN @s_klabc
      AND kna1~kukla IN @s_kukla
      AND likp~lfart IN @s_lfart
      AND kna1~kukla IN @s_kukla
      AND likp~zbstnk    IN @s_zbstnk
      AND lips~zwbxtbs   IN @s_zwbxt
      AND adr6~smtp_addr IN @s_smtp
      AND likp~zwlgs IN @s_zwlgs
      AND likp~zkddh IN @s_zkddh
      AND lips~werks IN @s_werks.

  IF gt_data IS NOT INITIAL.
    DATA:BEGIN OF gt_vbfa OCCURS 0,
           vbelv TYPE vbfa-vbelv,
           posnv TYPE vbfa-posnv,
           rfmng TYPE vbfa-rfmng,
         END OF gt_vbfa.

    SELECT vbelv,
           posnv,
           rfmng,
           plmin FROM vbfa
      WHERE vbtyp_n IN ( 'R','H','h' ) AND vbtyp_v = 'J'
      INTO TABLE @DATA(lt_vbfa).
    SORT lt_vbfa BY vbelv posnv.

    LOOP AT lt_vbfa INTO DATA(ls_vbfa).
      IF ls_vbfa-plmin = '-' .
        ls_vbfa-rfmng = ls_vbfa-rfmng * -1.
      ENDIF.

      MOVE-CORRESPONDING ls_vbfa TO gt_vbfa.
      COLLECT gt_vbfa.
      CLEAR:gt_vbfa.
    ENDLOOP.

    LOOP AT gt_data ASSIGNING <fs_data>.
      READ TABLE gt_vbfa[] INTO gt_vbfa WITH KEY vbelv = <fs_data>-vbeln  posnv = <fs_data>-posnr BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_data>-rfmng = gt_vbfa-rfmng.
      ENDIF.


      IF <fs_data>-kwmeng IS NOT INITIAL.
        "折前单价
        <fs_data>-zkzwi1 = <fs_data>-kzwi2 / <fs_data>-kwmeng.

        "折后单价
        <fs_data>-zkzwi2 = <fs_data>-kzwi1 / <fs_data>-kwmeng.
      ENDIF.

    ENDLOOP.
  ENDIF.



ENDFORM.


*&---------------------------------------------------------------------*
*& FORM FRM_BUILD_FIELD
*&---------------------------------------------------------------------*
*& TEXT
*&---------------------------------------------------------------------*
*&      <-- GT_FIELDCAT
*&---------------------------------------------------------------------*
FORM frm_build_field  CHANGING VALUE(ot_fieldcat) TYPE lvc_t_fcat.
  DATA : l_pos       TYPE i,
         ls_fieldcat TYPE lvc_s_fcat.
  DEFINE alv_append_field.
    CLEAR ls_fieldcat.
    ls_fieldcat-col_pos  = l_pos.
    ls_fieldcat-fieldname  = &1.
    ls_fieldcat-reptext = &2.
    ls_fieldcat-scrtext_l = &2.
    ls_fieldcat-scrtext_m = &2.
    ls_fieldcat-scrtext_s = &2.
    ls_fieldcat-key = &3.
    ls_fieldcat-ref_table = &4.
    ls_fieldcat-ref_field = &5.
    ls_fieldcat-hotspot = &6.
    ls_fieldcat-edit = &7.
    ls_fieldcat-no_zero = &8.
    APPEND ls_fieldcat TO ot_fieldcat.
    l_pos = l_pos + 1.
  END-OF-DEFINITION.

  REFRESH ot_fieldcat.
  l_pos = 1.

  alv_append_field 'vbeln    '     'SAP出货单号      '     '' 'likp '  'vbeln    ' ''  '' 'X'.
  alv_append_field 'posnr    '     'SAP出货行号      '     '' 'lips '  'posnr    ' ''  '' 'X'.
  alv_append_field 'zwlgs    '     '物流公司         '     '' 'likp '  'zwlgs    ' ''  '' 'X'.
  alv_append_field 'zkddh    '     '快递单号         '     '' 'likp '  'zkddh    ' ''  '' 'X'.
  alv_append_field 'bukrs    '     '销售公司         '     '' 'vbak '  'bukrs_vf ' ''  '' 'X'.
  alv_append_field 'butxt    '     '销售公司名称     '     '' 't001 '  'butxt    ' ''  '' 'X'.
  alv_append_field 'vtweg    '     '分销渠道         '     '' 'vbak '  'vtweg    ' ''  '' 'X'.
  alv_append_field 'vtext    '     '分销渠道名称     '     '' 'tvtwt'  'vtext    ' ''  '' 'X'.
  alv_append_field 'lfart    '     '出货类型       '     '' 'likp '  'lfart    ' ''  '' 'X'.
  alv_append_field 'zvtext   '     '订单类型名称     '     '' 'tvlkt'  'vtext    ' ''  '' 'X'.
  alv_append_field 'wadat    '     '计划交货日期     '     '' 'likp '  'wadat    ' ''  '' 'X'.
  alv_append_field 'wadat_ist'     '实际出货日期     '     '' 'likp '  'wadat_ist' ''  '' 'X'.
  alv_append_field 'zdpmc    '     '店铺/客户名称	   '     '' 'likp '  'zdpmc    ' ''  '' 'X'.
  alv_append_field 'bzirk    '     '销售地区       '     '' 'likp '  'bzirk    ' ''  '' 'X'.
  alv_append_field 'vkbur    '     '销售部门（一级） '     '' 'likp '  'vkbur    ' ''  '' 'X'.
  alv_append_field 'vkgrp    '     '销售部门（二级） '     '' 'vbak '  'vkgrp    ' ''  '' 'X'.
  alv_append_field 'land1    '     '国家         '     '' 'adrc '  'country  ' ''  '' 'X'.
  alv_append_field 'region   '     '省        '     '' 'adrc '  'region   ' ''  '' 'X'.
  alv_append_field 'mc_city1 '     '市        '     '' 'adrc '  'mc_city1 ' ''  '' 'X'.
  alv_append_field 'comp_head'     '区/县        '     '' 'bp001'  'comp_head' ''  '' 'X'.
  alv_append_field 'zywy     '     '业务员      '     '' 'vbak '  'zywy     ' ''  '' 'X'.
  alv_append_field 'zwbxtbs  '     '平台交易单号     '     '' 'lips '  'zwbxtbs  ' ''  '' 'X'.
  alv_append_field 'matnr    '     '产品代号/物料编码'     '' 'lips '  'matnr    ' ''  '' 'X'.
  alv_append_field 'maktx    '     '产品名称/物料名称'     '' 'makt '  'maktx    ' ''  '' 'X'.
  alv_append_field 'zcpxh    '     '产品类型       '     '' 'lips '  'zcpxh    ' ''  '' 'X'.
  alv_append_field 'lfimg    '     '计划交货数量     '     '' 'lips '  'lfimg    ' ''  '' 'X'.
  alv_append_field 'rfmng    '     '实际交货数量     '     '' 'vbfa '  'rfmng    ' ''  '' 'X'.
  alv_append_field 'werks    '     '出货工厂         '     '' 'lips '  'werks    ' ''  '' 'X'.
  alv_append_field 'lgort    '     '出货仓库         '     '' 'lips '  'lgort    ' ''  '' 'X'.
  alv_append_field 'zkzwi1   '     '折前单价         '     '' 'vbap '  'kzwi2    ' ''  '' 'X'.
  alv_append_field 'kzwi2    '     '折前金额         '     '' 'vbap '  'kzwi2    ' ''  '' 'X'.
  alv_append_field 'kzwi4    '     '促销折扣         '     '' 'vbap '  'kzwi4    ' ''  '' 'X'.
  alv_append_field 'kzwi6    '     '其他折扣         '     '' 'vbap '  'kzwi6    ' ''  '' 'X'.
  alv_append_field 'kzwi1    '     '折后金额         '     '' 'vbap '  'kzwi1    ' ''  '' 'X'.
  alv_append_field 'zkzwi2   '     '折后单价         '     '' 'vbap '  'kzwi1    ' ''  '' 'X'.
  alv_append_field 'zbstnk   '     'OMS订单号       '     '' 'likp '  'zbstnk   ' ''  '' 'X'.
  alv_append_field 'smtp_addr'     '客户邮箱         '     '' 'adr6 '  'smtp_addr' ''  '' 'X'.
  alv_append_field 'kukla    '     '客户分类         '     '' 'kna1 '  'kukla    ' ''  '' 'X'.
  alv_append_field 'zkhdj    '     '客户等级         '     '' 'vbak '  'zkhdj    ' ''  '' 'X'.
  alv_append_field 'waerk    '     '币种             '     '' 'vbap '  'waerk    ' ''  '' 'X'.
  alv_append_field 'cmkua    '     '汇率             '     '' 'vbap '  'cmkua    ' ''  '' 'X'.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM FRM_BUILD_LAYOUT
*&---------------------------------------------------------------------*
*& TEXT
*&---------------------------------------------------------------------*
*&      <-- GS_LAYOUT
*&---------------------------------------------------------------------*
FORM frm_build_layout CHANGING VALUE(os_layout) TYPE lvc_s_layo.
  CLEAR os_layout.
  os_layout-zebra = 'X'.             "斑马线
  os_layout-cwidth_opt = 'X'.        "自动调整列宽
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM FRM_DISPLAY_DATA_ALV
*&---------------------------------------------------------------------*
*& TEXT
*&---------------------------------------------------------------------*
*&      --> GT_FLIGHT
*&      <-- GT_FIELDCAT
*&      <-- GS_LAYOUT
*&      <-- GS_SETTING
*&---------------------------------------------------------------------*
FORM frm_display_data_alv  TABLES pt_otab TYPE STANDARD TABLE
                          CHANGING pt_fieldcat TYPE lvc_t_fcat
                                   ps_layout   TYPE lvc_s_layo
                                   ps_setting  TYPE lvc_s_glay.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'FRM_USER_COMMAND'
      i_callback_pf_status_set = 'FRM_STATUS_STANDARD'
      is_layout_lvc            = ps_layout
      it_fieldcat_lvc          = pt_fieldcat  "传入FIELDCAT
      i_grid_settings          = ps_setting
      i_save                   = 'A'         "STANDARD AND USER-SPECIFIC SAVING
    TABLES
      t_outtab                 = pt_otab[]    "传入输出内表
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM FRM_STATUS_STANDARD
*&---------------------------------------------------------------------*
*&  设置GUI状态(及用户界面)
*&---------------------------------------------------------------------*
FORM frm_status_standard USING pt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD' EXCLUDING pt_extab.
ENDFORM.

*&--------------------------------------------------------------------*
*&      FORM  FRM_USER_COMMAND
*&--------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
FORM frm_user_command USING pv_ucomm LIKE sy-ucomm
                            ps_selfield TYPE slis_selfield.
  "刷新"ALV输出表"数据
  DATA: lo_grid TYPE REF TO cl_gui_alv_grid.
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR' "获取ALV对象的函数
    IMPORTING
      e_grid = lo_grid.
  CALL METHOD lo_grid->check_changed_data.

  ps_selfield-refresh = 'X'. "刷新数据
  "用户触发功能码响应逻辑
  CASE pv_ucomm.
    WHEN OTHERS.
  ENDCASE.
  lo_grid->get_frontend_layout( IMPORTING es_layout = gs_layout )."获取layout
  gs_layout-cwidth_opt = 'X'.
  lo_grid->set_frontend_layout( is_layout = gs_layout ).  "重新设置layout

  "稳定刷新ALV
  DATA:stbl TYPE lvc_s_stbl.
  stbl-row = 'X'." 基于行的稳定刷新
  stbl-col = 'X'." 基于列稳定刷新
  CALL METHOD lo_grid->refresh_table_display
    EXPORTING
      is_stable = stbl.
ENDFORM.                    "FRM_USER_COMMAND
