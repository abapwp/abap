***&---------------------------------------------------------------------***
***& Program Name  :  ZRPSD002        　　　　    ***
***& Title         :  销售订单报表程序               ***
***& Module Name   :  SD                      ***
***& Sub-Module    :                         ***
***& Author        :  王钢稀                      ***
***& Create Date   :  2022-08-25                   ***
***& Logical DB    :  NOTHING                     ***
***& Program Type   : RP                               ***
***&---------------------------------------------------------------------***
*& REVISION LOG                                                        *
*& LOG#     DATE       AUTHOR        DESCRIPTION                       *
*& ----     ----       ----------    -----------                       *
*& 0000  2022-08-25    王钢稀           CREATE                          *
************************************************************************
REPORT zrppp003.

TABLES : vbak,adrc,adr6,bp001,knvv,vbap,mara,kna1.

TYPES : BEGIN OF ty_itab,
          vbeln     TYPE   vbak-vbeln       , "SAP订单号
          posnr     TYPE   vbap-posnr       , "SAP行号
          bukrs_vf  TYPE   vbak-bukrs_vf    , "销售公司
          butxt     TYPE   t001-butxt       , "销售公司名称
          vtweg     TYPE   vbak-vtweg       , "分销渠道
          vtext     TYPE   tvtwt-vtext      , "分销渠道名称
          auart     TYPE   vbak-auart       , "订单类型
          bezei     TYPE   tvakt-bezei      , "订单类型名称
          zfksj     TYPE   vbak-zfksj       , "接单日期
          kunnr     TYPE   vbak-kunnr       , "店铺/客户编码
          name1     TYPE   kna1-name1       , "店铺/客户名称
          bzirk     TYPE   knvv-bzirk       , "销售地区
          bztxt     TYPE   t171t-bztxt,
          vkbur     TYPE   vbak-vkbur       , "销售部门（一级）
          bezei_1   TYPE   tvkbt-bezei,
          vkgrp     TYPE   vbak-vkgrp       , "销售部门（二级）
          bezei_2   TYPE   tvgrt-bezei,
          zywy      TYPE   vbak-zywy        , "业务员
          zwbxtbs   TYPE   vbak-zwbxtbs     , "平台交易单号
          smjbz(50) TYPE   c                , "卖家备注
          mjbz(50)  TYPE   c                , "买家备注
          matnr     TYPE   vbap-matnr       , "产品代号/物料编码
          maktx     TYPE   makt-maktx       , "产品名称/物料名称
          zcpxh     TYPE   vbap-zcpxh       , "产品类型
          kwmeng    TYPE   vbap-kwmeng      , "订单数量
          zqdj      TYPE   vbap-kzwi2       , "折前单价
          kzwi2     TYPE   vbap-kzwi2       , "折前金额
          kzwi4     TYPE   vbap-kzwi4       , "促销折扣
          kzwi6     TYPE   vbap-kzwi6       , "其他折扣
          kzwi1     TYPE   vbap-kzwi1       , "折后金额
          zhdj      TYPE   vbap-kzwi1       , "折后单价
          yfhs      TYPE   vbap-kwmeng      , "已发货数
          wfhs      TYPE   vbap-kwmeng      , "未发货数
          dfhs      TYPE   vbap-kwmeng      , "待发货数
          kzwi1_xs  TYPE   vbap-kzwi1       , "销售金额
          besta     TYPE   vbap-besta       , "发货状态
          bstnk     TYPE   vbak-bstnk       , "OMS订单号
          smtp_addr TYPE   adr6-smtp_addr   , "客户邮箱
          kukla     TYPE   kna1-kukla       , "客户分类
          zkhdj     TYPE   vbak-zkhdj       , "客户等级
          waerk     TYPE   vbap-waerk       , "币种
          cmkua     TYPE   vbap-cmkua       , "汇率
          date      TYPE   sy-datum,
          time      TYPE   sy-uzeit,
        END OF ty_itab.



DATA gt_itab TYPE TABLE OF ty_itab.
DATA gw_itab TYPE          ty_itab.

* 定义 ALV 参数
DATA:  gw_layout  TYPE lvc_s_layo.
DATA: gw_fieldcat TYPE lvc_s_fcat,
      gt_fieldcat TYPE lvc_t_fcat.

FIELD-SYMBOLS <fs_itab> TYPE ty_itab.

"excel文档类对象
DATA:lo_excel TYPE REF TO zcl_excel.
"excel worksheet类对象
DATA:lo_worksheet TYPE REF TO zcl_excel_worksheet.
"excel 异常类对象
DATA:lf_cxexcel TYPE REF TO zcx_excel.


DATA:vid   TYPE vrm_id , "屏幕字段(可以是单个的I/O空间或者是Table Control中的一个单元格)
     list  TYPE vrm_values,
     value LIKE LINE OF list.
*----------------------------------------------------------------------*
*选择屏幕
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
  SELECT-OPTIONS :
*    s_zfksj   FOR  vbak-zfksj            ,  " 平台订单付款时间
    s_date    FOR  sy-datum ,
    s_time    FOR  sy-uzeit ,
    s_kunnr   FOR  vbak-kunnr            ,  " 客户编码
    s_land1   FOR  adrc-country          ,  " 国家
    s_regio   FOR  adrc-region           ,  " 省
    s_ort01   FOR  adrc-mc_city1         ,  " 市
    s_comp    FOR  bp001-comp_head       ,  " 区/县
    s_bzirk   FOR  knvv-bzirk            ,  " 销售地区
    s_vkorg   FOR  knvv-vkorg            ,  " 销售组织
    s_vtweg   FOR  knvv-vtweg            ,  " 分销渠道
    s_vkbur   FOR  knvv-vkbur            ,  " 销售部门（一级）
    s_vkgrp   FOR  knvv-vkgrp            ,  " 销售部门（二级）
    s_zcpxh   FOR  vbap-zcpxh            ,  " 产品型号（SPU）
    s_matnr   FOR  vbap-matnr            ,  " 产品代号（SKU）
    s_klabc   FOR  knvv-klabc            ,  " 客户等级
    s_kukla   FOR  kna1-kukla            ,  " 客户分类
    s_zywy    FOR  vbak-zywy             ,  " 业务员
    s_auart   FOR  vbak-auart            ,  " 订单类型
    s_bstnk   FOR  vbak-bstnk            ,  " OMS订单号
    s_smtp    FOR  adr6-smtp_addr        ,  " 客户邮箱
    s_ext     FOR  vbak-ext_bus_syst_id  .  " 平台交易单号

  PARAMETERS p_lsbox(20) TYPE c AS LISTBOX VISIBLE LENGTH 20 DEFAULT '0'.

SELECTION-SCREEN END OF BLOCK b1.


*初始化时下拉框赋值
INITIALIZATION.

AT SELECTION-SCREEN OUTPUT .
  REFRESH list .
  value-key = '0' .  "这个就是变量P_LIST的值
  value-text = '全部' . "这个是text
  APPEND value TO list .
  value-key = 'A' .  "这个就是变量P_LIST的值
  value-text = '未发货' . "这个是text
  APPEND value TO list .
  value-key = 'B' .
  value-text = '部分发货' .
  APPEND value TO list .
  value-key = 'C' .
  value-text = '完全发货' .
  APPEND value TO list .
**调用下拉框赋值函数
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_LSBOX'
      values = list.


START-OF-SELECTION.

  PERFORM frm_get_data.
  PERFORM frm_set_layout.
  PERFORM frm_set_fieldcat.
  PERFORM frm_display_alv.

FORM frm_get_data.

  DATA lv_besta TYPE vbap-besta.

  IF p_lsbox NE '0'.
    lv_besta = p_lsbox.

    SELECT vbak~vbeln     ,
       vbap~posnr     ,
       vbak~bukrs_vf  ,
       t001~butxt     ,
       vbak~vtweg     ,
       tvtwt~vtext    ,
       vbak~auart     ,
       tvakt~bezei    ,
       vbak~zfksj     ,
       vbak~kunnr     ,
       kna1~name1     ,
       knvv~bzirk     ,
       vbak~vkbur     ,
       vbak~vkgrp     ,
       vbak~zywy      ,
       vbak~zwbxtbs   ,
       vbap~matnr     ,
       makt~maktx     ,
       vbap~zcpxh     ,
       vbap~kwmeng    ,
       vbap~kzwi2     ,
       vbap~kzwi4     ,
       vbap~kzwi6     ,
       vbap~kzwi1     ,
       vbap~besta     ,
       vbak~bstnk     ,
       adr6~smtp_addr ,
       kna1~kukla     ,
       vbak~zkhdj     ,
       vbap~waerk     ,
*       vbfa~rfmng AS yfhs ,
       vbap~cmkua
  INTO CORRESPONDING FIELDS OF TABLE @gt_itab
  FROM vbap
  INNER JOIN vbak ON vbak~vbeln = vbap~vbeln
  LEFT JOIN knvv ON knvv~kunnr = vbak~kunnr AND knvv~vkorg = vbak~vkorg
  AND knvv~vtweg = vbak~vtweg AND knvv~spart = vbak~spart
  LEFT JOIN t001 ON t001~bukrs = vbak~bukrs_vf

  LEFT JOIN kna1 ON kna1~kunnr = vbak~kunnr
  LEFT JOIN adrc ON adrc~addrnumber = kna1~adrnr
  LEFT JOIN adr6 ON adr6~addrnumber = kna1~adrnr

  LEFT JOIN cvi_cust_link ON cvi_cust_link~customer = kna1~kunnr
  LEFT JOIN but000 ON but000~partner_guid = cvi_cust_link~partner_guid
  LEFT JOIN bp001 ON bp001~partner = but000~partner

  LEFT JOIN makt ON makt~matnr = vbap~matnr AND makt~spras = @sy-langu
  LEFT JOIN tvtwt ON tvtwt~vtweg = vbak~vtweg AND tvtwt~spras = @sy-langu
  LEFT JOIN tvakt ON tvakt~auart = vbak~auart AND tvakt~spras = @sy-langu
*  LEFT JOIN vbfa ON vbfa~vbelv = vbap~vbeln AND vbfa~posnv = vbap~posnr AND vbfa~vbtyp_n = 'R'
  WHERE
        vbak~kunnr               IN  @s_kunnr
*  and      vbak~zfksj               IN  @s_zfksj
  AND   adrc~country             IN  @s_land1
  AND   adrc~region              IN  @s_regio
  AND   adrc~mc_city1            IN  @s_ort01
  AND   bp001~comp_head          IN  @s_comp
  AND   knvv~bzirk               IN  @s_bzirk
  AND   knvv~vkorg               IN  @s_vkorg
  AND   knvv~vtweg               IN  @s_vtweg
  AND   knvv~vkbur               IN  @s_vkbur
  AND   knvv~vkgrp               IN  @s_vkgrp
  AND   vbap~zcpxh               IN  @s_zcpxh
  AND   vbap~matnr               IN  @s_matnr
  AND   knvv~klabc               IN  @s_klabc
  AND   kna1~kukla               IN  @s_kukla
  AND   vbak~zywy                IN  @s_zywy
  AND   vbak~auart               IN  @s_auart
  AND   vbak~bstnk               IN  @s_bstnk
  AND   adr6~smtp_addr           IN  @s_smtp
  AND   vbap~besta  =  @lv_besta
  AND   vbak~ext_bus_syst_id     IN  @s_ext .

  ELSE.

    SELECT vbak~vbeln     ,
       vbap~posnr     ,
       vbak~bukrs_vf  ,
       t001~butxt     ,
       vbak~vtweg     ,
       tvtwt~vtext    ,
       vbak~auart     ,
       tvakt~bezei    ,
       vbak~zfksj     ,
       vbak~kunnr     ,
       kna1~name1     ,
       knvv~bzirk     ,
       vbak~vkbur     ,
       vbak~vkgrp     ,
       vbak~zywy      ,
       vbak~zwbxtbs   ,
       vbap~matnr     ,
       makt~maktx     ,
       vbap~zcpxh     ,
       vbap~kwmeng    ,
       vbap~kzwi2     ,
       vbap~kzwi4     ,
       vbap~kzwi6     ,
       vbap~kzwi1     ,
       vbap~besta     ,
       vbak~bstnk     ,
       adr6~smtp_addr ,
       kna1~kukla     ,
       vbak~zkhdj     ,
       vbap~waerk     ,
*       vbfa~rfmng AS yfhs ,
       vbap~cmkua
  INTO CORRESPONDING FIELDS OF TABLE @gt_itab
  FROM vbap
  INNER JOIN vbak ON vbak~vbeln = vbap~vbeln
  LEFT JOIN knvv ON knvv~kunnr = vbak~kunnr AND knvv~vkorg = vbak~vkorg
  AND knvv~vtweg = vbak~vtweg AND knvv~spart = vbak~spart
  LEFT JOIN t001 ON t001~bukrs = vbak~bukrs_vf

  LEFT JOIN kna1 ON kna1~kunnr = vbak~kunnr
  LEFT JOIN adrc ON adrc~addrnumber = kna1~adrnr
  LEFT JOIN adr6 ON adr6~addrnumber = kna1~adrnr

  LEFT JOIN cvi_cust_link ON cvi_cust_link~customer = kna1~kunnr
  LEFT JOIN but000 ON but000~partner_guid = cvi_cust_link~partner_guid
  LEFT JOIN bp001 ON bp001~partner = but000~partner

  LEFT JOIN makt ON makt~matnr = vbap~matnr AND makt~spras = @sy-langu
  LEFT JOIN tvtwt ON tvtwt~vtweg = vbak~vtweg AND tvtwt~spras = @sy-langu
  LEFT JOIN tvakt ON tvakt~auart = vbak~auart AND tvakt~spras = @sy-langu
*  LEFT JOIN vbfa ON vbfa~vbelv = vbap~vbeln AND vbfa~posnv = vbap~posnr AND vbfa~vbtyp_n = 'R'
  WHERE vbak~kunnr               IN  @s_kunnr
*  AND   vbak~zfksj               IN  @s_zfksj
  AND   adrc~country             IN  @s_land1
  AND   adrc~region              IN  @s_regio
  AND   adrc~mc_city1            IN  @s_ort01
  AND   bp001~comp_head          IN  @s_comp
  AND   knvv~bzirk               IN  @s_bzirk
  AND   knvv~vkorg               IN  @s_vkorg
  AND   knvv~vtweg               IN  @s_vtweg
  AND   knvv~vkbur               IN  @s_vkbur
  AND   knvv~vkgrp               IN  @s_vkgrp
  AND   vbap~zcpxh               IN  @s_zcpxh
  AND   vbap~matnr               IN  @s_matnr
  AND   knvv~klabc               IN  @s_klabc
  AND   kna1~kukla               IN  @s_kukla
  AND   vbak~zywy                IN  @s_zywy
  AND   vbak~auart               IN  @s_auart
  AND   vbak~bstnk               IN  @s_bstnk
  AND   adr6~smtp_addr           IN  @s_smtp
*  AND   vbap~besta  =  @lv_besta
  AND   vbak~ext_bus_syst_id     IN  @s_ext .
  ENDIF.

*  IF gt_itab is not INITIAL.
*    select * into table @data(lt_kna1)
*      from kna1
*      FOR ALL ENTRIES IN @gt_itab
*      where kunnr = @gt_itab-kunnr.
*
*    select * into table @data(lt_adr6)
*      from adr6
*      for ALL ENTRIES IN @lt_kna1
*      where addrnumber = @lt_kna1-adrnr  .
*
*    select * into table @data(lt_adrc)
*      from adrc
*      for ALL ENTRIES IN @lt_kna1
*      where addrnumber = @lt_kna1-adrnr  .
*
*    select * into table @data(lt_ci)
*      from cvi_cust_link
*      for ALL ENTRIES IN @lt_kna1
*      where customer = @lt_kna1-kunnr .
*
*    select * into table @data(lt_bt)
*      from but000
*      FOR ALL ENTRIES IN @lt_ci
*      where partner_guid = @lt_ci-partner_guid .
*
*    select * into table @data(lt_bp)
*      from bp001
*      FOR ALL ENTRIES IN @lt_bt
*      where partner = @lt_bt-partner .
*
*  ENDIF.

  IF gt_itab IS NOT INITIAL.

    SELECT matnr,kalab,vbeln,posnr INTO TABLE @DATA(lt_mska)
      FROM mska
      FOR ALL ENTRIES IN @gt_itab
      WHERE matnr = @gt_itab-matnr
        AND vbeln = @gt_itab-vbeln
        AND posnr = @gt_itab-posnr .

    SORT lt_mska BY vbeln posnr .

    SELECT ruuid,vbelv,posnv,vbtyp_n,rfmng INTO TABLE @DATA(lt_vbfa)
      FROM vbfa
      FOR ALL ENTRIES IN @gt_itab
      WHERE vbelv = @gt_itab-vbeln
      AND posnv = @gt_itab-posnr
      AND vbtyp_n = 'R' .

    SORT lt_vbfa BY vbelv posnv.

    SELECT bzirk,spras,bztxt INTO TABLE @DATA(lt_t171t)
      FROM t171t
      FOR ALL ENTRIES IN @gt_itab
      WHERE bzirk = @gt_itab-bzirk AND spras = @sy-langu .

    SELECT vkbur,spras,bezei INTO TABLE @DATA(lt_tvkbt)
      FROM tvkbt
      FOR ALL ENTRIES IN @gt_itab
      WHERE vkbur = @gt_itab-vkbur AND spras = @sy-langu .

    SELECT vkgrp,spras,bezei INTO TABLE @DATA(lt_tvgrt)
      FROM tvgrt
      FOR ALL ENTRIES IN @gt_itab
      WHERE vkgrp = @gt_itab-vkgrp AND spras = @sy-langu .

  ENDIF.

  SORT gt_itab BY vbeln posnr.

  DATA l_text LIKE TABLE OF tline WITH HEADER LINE.
  DATA lv_name TYPE thead-tdname.


  LOOP AT gt_itab ASSIGNING <fs_itab>.

    " 销售 地区 、 部门 赋值
    READ TABLE lt_t171t INTO DATA(lw_t171t)
      WITH KEY bzirk = <fs_itab>-bzirk.
    IF sy-subrc = 0.
      <fs_itab>-bztxt = lw_t171t-bztxt .
    ENDIF.

    READ TABLE lt_tvkbt INTO DATA(lw_tvkbt)
      WITH KEY vkbur = <fs_itab>-vkbur.
    IF sy-subrc = 0.
      <fs_itab>-bezei_1 = lw_tvkbt-bezei .
    ENDIF.

    READ TABLE lt_tvgrt INTO DATA(lw_tvgrt)
      WITH KEY vkgrp = <fs_itab>-vkgrp .
    IF sy-subrc = 0.
      <fs_itab>-bezei_2 = lw_tvgrt-bezei .
    ENDIF.

    IF <fs_itab>-kwmeng NE 0 .
      <fs_itab>-zqdj = <fs_itab>-kzwi2 / <fs_itab>-kwmeng .
      <fs_itab>-zhdj = <fs_itab>-kzwi1 / <fs_itab>-kwmeng .
    ENDIF.

    <fs_itab>-kzwi1_xs = <fs_itab>-kzwi1.


    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = <fs_itab>-vbeln
      IMPORTING
        output = <fs_itab>-vbeln.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = <fs_itab>-posnr
      IMPORTING
        output = <fs_itab>-posnr.

    CLEAR lv_name.
    REFRESH l_text[].
    CLEAR l_text.

    lv_name = <fs_itab>-vbeln && <fs_itab>-posnr.
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = sy-mandt
        id                      = '0001'
        language                = sy-langu
        name                    = lv_name
        object                  = 'VBBP'
      TABLES
        lines                   = l_text[]
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
    ENDIF.
    LOOP AT l_text.
      <fs_itab>-mjbz = <fs_itab>-mjbz && l_text-tdline.
    ENDLOOP.


    REFRESH l_text[].
    CLEAR l_text.
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = sy-mandt
        id                      = '0002'
        language                = sy-langu
        name                    = lv_name
        object                  = 'VBBP'
      TABLES
        lines                   = l_text[]
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
    ENDIF.
    LOOP AT l_text.
      <fs_itab>-smjbz = <fs_itab>-smjbz && l_text-tdline.
    ENDLOOP.


    READ TABLE lt_mska INTO DATA(ls_mska)
      WITH KEY matnr = <fs_itab>-matnr vbeln = <fs_itab>-vbeln posnr = <fs_itab>-posnr .
    IF sy-subrc = 0.
      <fs_itab>-dfhs = ls_mska-kalab .
    ENDIF.

    READ TABLE lt_vbfa INTO DATA(ls_vbfa)
      WITH KEY vbelv = <fs_itab>-vbeln posnv = <fs_itab>-posnr vbtyp_n = 'R' .
    IF sy-subrc = 0.
      <fs_itab>-yfhs = ls_vbfa-rfmng.
    ENDIF.
    <fs_itab>-wfhs = <fs_itab>-kwmeng - <fs_itab>-yfhs .

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = <fs_itab>-vbeln
      IMPORTING
        output = <fs_itab>-vbeln.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = <fs_itab>-posnr
      IMPORTING
        output = <fs_itab>-posnr.

    IF <fs_itab>-auart EQ 'ZAR'
      OR <fs_itab>-auart EQ 'ZRE'
      OR <fs_itab>-auart EQ 'ZRE1'.

      <fs_itab>-kwmeng      =  <fs_itab>-kwmeng      *  ( -1 ).
      <fs_itab>-zqdj        =  <fs_itab>-zqdj        *  ( -1 ).
      <fs_itab>-kzwi2       =  <fs_itab>-kzwi2       *  ( -1 ).
      <fs_itab>-kzwi4       =  <fs_itab>-kzwi4       *  ( -1 ).
      <fs_itab>-kzwi6       =  <fs_itab>-kzwi6       *  ( -1 ).
      <fs_itab>-kzwi1       =  <fs_itab>-kzwi1       *  ( -1 ).
      <fs_itab>-zhdj        =  <fs_itab>-zhdj        *  ( -1 ).
      <fs_itab>-yfhs        =  <fs_itab>-yfhs        *  ( -1 ).
      <fs_itab>-wfhs        =  <fs_itab>-wfhs        *  ( -1 ).
      <fs_itab>-dfhs        =  <fs_itab>-dfhs        *  ( -1 ).
      <fs_itab>-kzwi1_xs    =  <fs_itab>-kzwi1_xs    *  ( -1 ).

    ENDIF.


    "  日期 、 时间 的处理
    IF <fs_itab>-zfksj IS NOT INITIAL.
      SPLIT <fs_itab>-zfksj AT space INTO DATA(lv_date) DATA(lv_time).
      <fs_itab>-date = lv_date+0(4) && lv_date+5(2) && lv_date+8(2) .
      <fs_itab>-time = lv_time+0(2) && lv_time+3(2) && lv_time+6(2) .
    ENDIF.


  ENDLOOP.

  IF s_date IS NOT INITIAL.
    DELETE gt_itab WHERE date NOT IN s_date .
  ENDIF.

  IF s_time IS NOT INITIAL.
    DELETE gt_itab WHERE time NOT IN s_time .
  ENDIF.


ENDFORM.

FORM frm_set_layout.

  gw_layout-zebra = 'X'.
  gw_layout-cwidth_opt = 'X'.
  gw_layout-sel_mode = 'A'.

ENDFORM.

FORM frm_set_fieldcat.

  PERFORM frm_create_fields USING:
    'VBELN      ' 'SAP订单号  ' ,
    'POSNR      ' 'SAP行号  ' ,
    'BUKRS_VF   ' '销售公司      ' ,
    'BUTXT      ' '销售公司名称  ' ,
    'VTWEG      ' '分销渠道  ' ,
    'VTEXT      ' '分销渠道名称  ' ,
    'AUART      ' '订单类型  ' ,
    'BEZEI      ' '订单类型名称  ' ,
*    'ZFKSJ      ' '接单日期  ' ,
    'DATE      ' '接单日期  ' ,
    'TIME      ' '接单时间  ' ,
    'KUNNR      ' '店铺/客户编码  ' ,
    'NAME1      ' '店铺/客户名称  ' ,
    'BZIRK      ' '销售地区  ' ,
    'BZTXT      ' '销售地区名称  ' ,
    'VKBUR      ' '销售部门(一级)  ' ,
    'BEZEI_1      ' '销售部门(一级)名称  ' ,
    'VKGRP      ' '销售部门(二级)  ' ,
    'BEZEI_2      ' '销售部门(二级)名称  ' ,
    'ZYWY       ' '业务员  ' ,
    'ZWBXTBS    ' '平台交易单号  ' ,
    'SMJBZ  ' '卖家备注  ' ,
    'MJBZ   ' '买家备注  ' ,
    'MATNR      ' '产品代号/物料编码  ' ,
    'MAKTX      ' '产品名称/物料名称  ' ,
    'ZCPXH      ' '产品类型  ' ,
    'KWMENG     ' '订单数量  ' ,
    'ZQDJ       ' '折前单价  ' ,
    'KZWI2      ' '折前金额  ' ,
    'KZWI4      ' '促销折扣  ' ,
    'KZWI6      ' '其他折扣  ' ,
    'KZWI1      ' '折后金额  ' ,
    'ZHDJ       ' '折后单价  ' ,
    'YFHS       ' '已发货数  ' ,
    'WFHS       ' '未发货数  ' ,
    'DFHS       ' '待发货数  ' ,
    'KZWI1_XS   ' '销售金额  ' ,
    'BESTA      ' '发货状态  ' ,
    'BSTNK      ' 'OMS订单号  ' ,
    'SMTP_ADDR  ' '客户邮箱  ' ,
    'KUKLA      ' '客户分类  ' ,
    'ZKHDJ      ' '客户等级  ' ,
    'WAERK      ' '币种  ' ,
    'CMKUA      ' '汇率  ' .

  " 解决 因为 字段长度不够，导致 alv自带的筛选 筛选不到的问题
  gt_fieldcat[ fieldname = 'BUTXT' ]-intlen = '100'.
  gt_fieldcat[ fieldname = 'VTEXT' ]-intlen = '20'.
  gt_fieldcat[ fieldname = 'BEZEI' ]-intlen = '20'.
  gt_fieldcat[ fieldname = 'NAME1' ]-intlen = '35'.
  gt_fieldcat[ fieldname = 'BZTXT' ]-intlen = '20'.
  gt_fieldcat[ fieldname = 'BEZEI_1' ]-intlen = '20'.
  gt_fieldcat[ fieldname = 'BEZEI_2' ]-intlen = '20'.
  gt_fieldcat[ fieldname = 'MAKTX' ]-intlen = '40'.
  gt_fieldcat[ fieldname = 'MATNR' ]-intlen = '40'.
  gt_fieldcat[ fieldname = 'BSTNK' ]-intlen = '20'.
  gt_fieldcat[ fieldname = 'SMTP_ADDR' ]-intlen = '241'.


ENDFORM.
FORM frm_create_fields  USING pv_fieldname pv_reptext .
  INSERT VALUE #(
     fieldname = pv_fieldname
     reptext   = pv_reptext
     )
     INTO TABLE gt_fieldcat.
ENDFORM.

*ALV
FORM frm_display_alv."(内表作参数)
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'FRM_ALV_STATUS '    "状态
      i_callback_user_command  = 'FRM_ALV_COMMAND '   "ALV状态栏按钮
      is_layout_lvc            = gw_layout
      it_fieldcat_lvc          = gt_fieldcat
    TABLES
      t_outtab                 = gt_itab.
ENDFORM.

FORM frm_alv_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'.   "状态NAME
ENDFORM.

* 状态栏按钮操作
FORM frm_alv_command  USING r_ucomm LIKE sy-ucomm
                             rs_selfield TYPE slis_selfield.
  DATA:lo_guid TYPE REF TO cl_gui_alv_grid.
  DATA:stbl TYPE lvc_s_stbl.
  stbl-row = 'X'." 基于行的稳定刷新
  stbl-col = 'X'." 基于列稳定刷新
  "获取ALV对象的函数
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = lo_guid.
  CALL METHOD lo_guid->check_changed_data.
  CALL METHOD lo_guid->refresh_table_display
    EXPORTING
      is_stable = stbl.
  rs_selfield-refresh = 'X'.
  rs_selfield-col_stable = 'X'.
  rs_selfield-row_stable = 'X'.

  "用户点击触发 (此处才是关键部分)
  CASE r_ucomm.
    WHEN ''.
  ENDCASE.
ENDFORM.
