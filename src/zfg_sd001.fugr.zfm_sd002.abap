FUNCTION zfm_sd002.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(I_CONFIG) TYPE  CHAR2 OPTIONAL
*"     VALUE(I_KUNNR) TYPE  KNA1-KUNNR OPTIONAL
*"  EXPORTING
*"     VALUE(STATUS) TYPE  CHAR1
*"     VALUE(MESSAGE) TYPE  CHAR255
*"  TABLES
*"      LT_KUNNR_TAB STRUCTURE  ZSSD002_KUNNR_TAB OPTIONAL
*"      LT_BASIC_TAB TYPE  ZTTSD002_BASIC OPTIONAL
*"----------------------------------------------------------------------
  DATA: zt_basic_data  TYPE TABLE OF zssd001_basic WITH HEADER LINE,   "客户主数据-基本数据
        zt_basic_data1 TYPE TABLE OF zssd001_basic,
        zt_fi_data     TYPE TABLE OF zssd001_fi WITH HEADER LINE,      "客户主数据-公司代码
        zt_sales_data  TYPE TABLE OF zssd001_sales WITH HEADER LINE,   "客户主数据-销售与分销
        zt_ukm_data    TYPE TABLE OF zssd001_ukm WITH HEADER LINE.     "客户主数据-客户信用明细
  DATA:ls_zdata TYPE zssd001_basic.

  DATA : lv_zflag TYPE char1.
  DATA : ls_data   TYPE zssd001.
  DATA : ls_data1  TYPE zssd001.
  DATA : lv_status TYPE string.
  DATA : lv_msg    TYPE string.
  DATA : lv_kunnr  TYPE zssd001_basic-kunnr.

*  IF i_config <> '10' AND i_config <> '20' AND i_config <> '30' AND i_config <> '40' AND i_config <> '50'.
*    IF message IS INITIAL.
*      status = 'E'.
*      message = '业务操作只能是10/20/30/40/50!'.
*    ELSE.
*      message = message && '业务操作只能是10/20/30/40/50!'.
*    ENDIF.
*  ENDIF.
*
*  CHECK status <> 'E'.

  IF i_config NE '50' .
    LOOP AT lt_kunnr_tab INTO DATA(ls_kunnr_tab).
      IF i_config = '10'.
        lv_zflag = 'I'.
      ELSEIF i_config = '20'.
        lv_zflag = 'U'.
      ELSEIF i_config = '30'.
        lv_zflag = 'D'.
      ELSEIF i_config = '40'.
        lv_zflag = 'R'.
      ENDIF.
*&------------------------------------------------------------------
      IF i_config = '10' OR i_config = '20' OR i_config = '40'.
        "1、客户主数据-基本数据.
        CLEAR:zt_basic_data,zt_basic_data[].
        CLEAR:ls_data.
        zt_basic_data-zflag      = lv_zflag.
        zt_basic_data-ktokd      = ls_kunnr_tab-ktokd.
        zt_basic_data-kukla      = ls_kunnr_tab-kukla.
        zt_basic_data-kunnr      = ls_kunnr_tab-kunnr.
        zt_basic_data-name1      = ls_kunnr_tab-name1.
        zt_basic_data-mcod1      = ls_kunnr_tab-mcod1.
        zt_basic_data-mcod2      = ls_kunnr_tab-mcod2.
        zt_basic_data-land1      = ls_kunnr_tab-land1.
        zt_basic_data-regio      = ls_kunnr_tab-regio.
        zt_basic_data-ort01      = ls_kunnr_tab-ort01.
        zt_basic_data-comph      = ls_kunnr_tab-comph.
        zt_basic_data-pstlz      = ls_kunnr_tab-pstlz.
        zt_basic_data-spras      = ls_kunnr_tab-spras.
        zt_basic_data-name_co    = ls_kunnr_tab-name_co.
        zt_basic_data-telf1      = ls_kunnr_tab-telf1.
        zt_basic_data-smtp_addr  = ls_kunnr_tab-smtp_addr.
        zt_basic_data-telfx      = ls_kunnr_tab-telfx.
        zt_basic_data-street     = ls_kunnr_tab-str+0(60).
        zt_basic_data-str_suppl1 = ls_kunnr_tab-str+60(40).
        zt_basic_data-str_suppl2 = ls_kunnr_tab-str+100(40).
        zt_basic_data-taxtype    = ls_kunnr_tab-taxtype.
        zt_basic_data-taxnum     = ls_kunnr_tab-taxnum.
        zt_basic_data-waers      = ls_kunnr_tab-waers.
        zt_basic_data-cap_incr_a = ls_kunnr_tab-cap_incr_a.
        APPEND zt_basic_data.

        ls_data-zbasic = 'X'.
        ls_data-zt_basic_data    = zt_basic_data[].
        CALL FUNCTION 'ZFM_SD001'
          EXPORTING
            fs_sdjfh = ls_data
          IMPORTING
            status   = lv_status
            msg      = lv_msg.
        IF lv_status = 'E'."创建失败
          status = 'E'.
          message = lv_msg.
        ELSE.
          "反序列json解析
          /ui2/cl_json=>deserialize( EXPORTING json  = lv_msg
                                      CHANGING  data = ls_data1 ).
          zt_basic_data1[] = ls_data1-zt_basic_data.
          READ TABLE zt_basic_data1 INTO ls_zdata INDEX 1.
          lv_kunnr = ls_zdata-kunnr.
          lv_msg   = ls_zdata-zmessage.

          status = 'S'.
          message = lv_msg.
        ENDIF.
        ls_kunnr_tab-ztype    = lv_status.
        ls_kunnr_tab-zmessage = lv_msg.
        ls_kunnr_tab-kunnr    = lv_kunnr.


      ENDIF.
*&------------------------------------------------------------------
      "2、客户主数据-公司代码数据
      IF ( ( i_config = '10' OR i_config = '20' OR i_config = '40' ) AND ls_kunnr_tab-ztype = 'S' ).
        CLEAR:zt_fi_data,zt_fi_data[].
        CLEAR:ls_data.
        zt_fi_data-zflag = lv_zflag.
        zt_fi_data-kunnr = lv_kunnr.
        zt_fi_data-bukrs = ls_kunnr_tab-bukrs.
        zt_fi_data-akont = ls_kunnr_tab-akont.
        zt_fi_data-zterm = ls_kunnr_tab-zterm.
        zt_fi_data-zuawa = ls_kunnr_tab-zuawa.
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
          status = 'E'.
          message = message && lv_msg.
        ELSE.
          lv_msg     = '公司代码创建成功'.
          status = 'S'.
          message = message && lv_msg.
        ENDIF.
        ls_kunnr_tab-ztype    = lv_status.
        CONCATENATE ls_kunnr_tab-zmessage '/' lv_msg INTO ls_kunnr_tab-zmessage.
      ENDIF.
*&------------------------------------------------------------------
      "3、客户主数据-销售视图数据
      IF ( ( i_config = '10' OR i_config = '20' OR i_config = '40' ) AND ls_kunnr_tab-ztype = 'S' )
         OR i_config = '30'.

        CLEAR:zt_sales_data,zt_sales_data[].
        CLEAR:ls_data.
        zt_sales_data-zflag   = lv_zflag.
        zt_sales_data-kunnr   = lv_kunnr.
        zt_sales_data-vkorg   = ls_kunnr_tab-vkorg.
        zt_sales_data-vtweg   = ls_kunnr_tab-vtweg.
        zt_sales_data-spart   = ls_kunnr_tab-spart.
        zt_sales_data-vkbur   = ls_kunnr_tab-vkbur.
        zt_sales_data-vkgrp   = ls_kunnr_tab-vkgrp.
        zt_sales_data-bzirk   = ls_kunnr_tab-bzirk.
        zt_sales_data-klabc   = ls_kunnr_tab-klabc.
        zt_sales_data-zywyn   = ls_kunnr_tab-zywyn.
        zt_sales_data-waers   = ls_kunnr_tab-waers1.
        zt_sales_data-kalks   = ls_kunnr_tab-kalks.
        zt_sales_data-vsbed   = ls_kunnr_tab-vsbed.
        zt_sales_data-kzazu   = ls_kunnr_tab-kzazu.
        zt_sales_data-vwerk   = ls_kunnr_tab-vwerk.
        zt_sales_data-inco1   = ls_kunnr_tab-inco1.
        zt_sales_data-inco2_l = ls_kunnr_tab-inco2_l.
        zt_sales_data-zterm   = ls_kunnr_tab-zterm1.
        zt_sales_data-ktgrd   = ls_kunnr_tab-ktgrd.
        zt_sales_data-taxkd   = ls_kunnr_tab-taxkd.
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
          status = 'E'.
          message = message && lv_msg.
        ELSE.
          lv_msg = '销售视图创建成功'.
          status = 'S'.
          message = message && lv_msg.
        ENDIF.

        ls_kunnr_tab-ztype    = lv_status.
        CONCATENATE ls_kunnr_tab-zmessage '/' lv_msg INTO ls_kunnr_tab-zmessage.
      ENDIF.
*&------------------------------------------------------------------
      "4、客户信用主数据
      IF ( ( i_config = '10' OR i_config = '20' ) AND ls_kunnr_tab-ztype = 'S' ).
        CLEAR:zt_ukm_data,zt_ukm_data[].
        CLEAR:ls_data.
        zt_ukm_data-zflag            = lv_zflag.
        zt_ukm_data-kunnr            = lv_kunnr.
        zt_ukm_data-risk_class       = ls_kunnr_tab-risk_class.
        zt_ukm_data-limit_rule       = ls_kunnr_tab-limit_rule.
        zt_ukm_data-check_rule       = ls_kunnr_tab-check_rule.
        zt_ukm_data-credit_sgmnt     = ls_kunnr_tab-credit_sgmnt.
        zt_ukm_data-credit_limit     = ls_kunnr_tab-credit_limit.
        zt_ukm_data-limit_valid_date = ls_kunnr_tab-limit_valid_date.
        APPEND zt_ukm_data.

        ls_data-zukm = 'X'  .
        ls_data-zt_ukm_data    = zt_ukm_data[].
        CALL FUNCTION 'ZFM_SD001'
          EXPORTING
*           FD_DATA  =
            fs_sdjfh = ls_data
          IMPORTING
            status   = lv_status
            msg      = lv_msg.
        IF lv_status = 'E'.
          status = 'E'.
          message = message && lv_msg.
        ELSE.
          lv_msg = '信用段创建成功'.
        ENDIF.
        ls_kunnr_tab-ztype    = lv_status.
        status = 'S'.
        message = message && lv_msg.
        CONCATENATE ls_kunnr_tab-zmessage '/' lv_msg INTO ls_kunnr_tab-zmessage.
      ENDIF.

      MODIFY lt_kunnr_tab FROM ls_kunnr_tab TRANSPORTING kunnr ztype zmessage.
    ENDLOOP.
  ELSE.
    DATA:lt_sales TYPE TABLE OF zssd002_sales_tab WITH HEADER LINE.
    DATA:lt_fi    TYPE TABLE OF zssd002_fi_tab WITH HEADER LINE.

    RANGES s_kunnr FOR kna1-kunnr.

    IF i_kunnr <> ''.
      s_kunnr-sign   = 'I'.
      s_kunnr-option = 'EQ'.
      s_kunnr-low    = i_kunnr.
      APPEND s_kunnr.
    ENDIF.

    "客户主数据-基本数据-KNA1
    SELECT
      a~ktokd,"客户组
      a~kukla,"客户分类
      a~kunnr,"客户编号
      a~name1,"名称1
      a~mcod1,"检索词对于匹配码搜索
      a~mcod2,"匹配码搜索的搜索条件
      a~land1,"国家/地区代码
      a~regio,"地区
      a~ort01,"城市
      a~pstlz,"邮政编码
      a~spras,"语言代码
      a~telf1,"电话
      a~telfx,"传真
      a~adrnr,
      a~loevm
      FROM kna1 AS a
      WHERE kunnr IN @s_kunnr
      INTO TABLE @DATA(lt_basic).

    SORT lt_basic BY kunnr.

    IF lt_basic[] IS NOT INITIAL.
      "销售数据-KNVV
      SELECT kunnr,vkorg,vtweg,spart,vkbur,vkgrp,bzirk,klabc,eikto,
             waers,kalks,vsbed,kzazu,vwerk,inco1,inco2_l,zterm,ktgrd,
             aufsd,lifsd,faksd,loevm
        FROM knvv
        FOR ALL ENTRIES IN @lt_basic
        WHERE kunnr = @lt_basic-kunnr
        INTO TABLE @DATA(lt_knvv).

      "公司代码-KNB1
      SELECT kunnr,bukrs,akont,zterm,zuawa,loevm
        FROM knb1
        FOR ALL ENTRIES IN @lt_basic
        WHERE kunnr = @lt_basic-kunnr
        INTO TABLE @DATA(lt_knb1).

      "信用段-UKMBP_CMS/UKMBP_CMS_SGM
      SELECT a~partner,a~credit_sgmnt,a~credit_limit,a~limit_valid_date,
             b~risk_class,b~limit_rule,b~check_rule
        FROM ukmbp_cms_sgm AS a
        LEFT JOIN ukmbp_cms AS b ON b~partner = a~partner
        FOR ALL ENTRIES IN @lt_basic
        WHERE a~partner = @lt_basic-kunnr
        INTO TABLE @DATA(lt_umk).

      "客户税分类-KNVI
      SELECT kunnr,taxkd
        FROM knvi
        FOR ALL ENTRIES IN @lt_basic
        WHERE kunnr = @lt_basic-kunnr
          AND aland = 'CN'
          AND tatyp = 'MWST'
        INTO TABLE @DATA(lt_knvi).

      "地址
      SELECT addrnumber,name_co,street,str_suppl1,str_suppl2,str_suppl3
        FROM adrc
        FOR ALL ENTRIES IN @lt_basic
        WHERE addrnumber = @lt_basic-adrnr
        INTO TABLE @DATA(lt_adrc).

      "税号-DFKKBPTAXNUM
      SELECT partner,taxtype,taxnum,taxnumxl
        FROM dfkkbptaxnum
        FOR ALL ENTRIES IN @lt_basic
        WHERE partner = @lt_basic-kunnr
        INTO TABLE @DATA(lt_dfkk).

      "电子邮箱-ADR6
      SELECT addrnumber,smtp_addr
        FROM adr6
        FOR ALL ENTRIES IN @lt_basic
        WHERE addrnumber = @lt_basic-adrnr
        INTO TABLE @DATA(lt_adr6).

      "注册资本 -BP001
      SELECT partner,comp_head,bal_sh_cur,cap_incr_a
        FROM bp001
        FOR ALL ENTRIES IN @lt_basic
        WHERE partner = @lt_basic-kunnr
        INTO TABLE @DATA(lt_bp001).
    ENDIF.

    SORT lt_knvv  BY kunnr vkorg vtweg spart.
    SORT lt_knb1  BY kunnr bukrs.
    SORT lt_umk   BY partner.
    SORT lt_knvi  BY kunnr.
    SORT lt_adrc  BY addrnumber.
    SORT lt_dfkk  BY partner.
    SORT lt_adr6  BY addrnumber.
    SORT lt_bp001 BY partner.

    LOOP AT lt_basic INTO DATA(ls_basic).
      CLEAR lt_basic_tab.
      lt_basic_tab-ktokd = ls_basic-ktokd.   "客户组
      lt_basic_tab-kukla = ls_basic-kukla.   "客户分类
      lt_basic_tab-kunnr = ls_basic-kunnr.   "客户编号
      lt_basic_tab-name1 = ls_basic-name1.   "名称1
      lt_basic_tab-mcod1 = ls_basic-mcod1.   "检索词对于匹配码搜索
      lt_basic_tab-mcod2 = ls_basic-mcod2.   "匹配码搜索的搜索条件
      lt_basic_tab-land1 = ls_basic-land1.   "国家/地区代码
      lt_basic_tab-regio = ls_basic-regio.   "地区
      lt_basic_tab-ort01 = ls_basic-ort01.   "城市
      lt_basic_tab-pstlz = ls_basic-pstlz.   "邮政编码
      lt_basic_tab-spras = ls_basic-spras.   "语言代码
      lt_basic_tab-telf1 = ls_basic-telf1.   "电话
      lt_basic_tab-telfx = ls_basic-telfx.   "传真
      READ TABLE lt_adrc INTO DATA(ls_adrc) WITH KEY addrnumber = ls_basic-adrnr BINARY SEARCH.
      IF sy-subrc = 0.
        lt_basic_tab-name_co = ls_adrc-name_co.    "采购员
        lt_basic_tab-str     = ls_adrc-street && ls_adrc-str_suppl1 && ls_adrc-str_suppl2 && ls_adrc-str_suppl3."地址
      ENDIF.
      READ TABLE lt_dfkk INTO DATA(ls_dfkk) WITH KEY partner = ls_basic-kunnr BINARY SEARCH.
      IF sy-subrc = 0.
        lt_basic_tab-taxtype = ls_dfkk-taxtype.   "税号类别
        lt_basic_tab-taxnum  = ls_dfkk-taxnum.    "税号
      ENDIF.
      READ TABLE lt_adr6 INTO DATA(ls_adr6) WITH KEY addrnumber = ls_basic-adrnr BINARY SEARCH.
      IF sy-subrc = 0.
        lt_basic_tab-smtp_addr = ls_adr6-smtp_addr.   "电子邮箱
      ENDIF.
      READ TABLE lt_bp001 INTO DATA(ls_bp001) WITH KEY partner = ls_basic-kunnr BINARY SEARCH.
      IF sy-subrc = 0.
        lt_basic_tab-comph      = ls_bp001-comp_head.    "区/县
        lt_basic_tab-waers      = ls_bp001-bal_sh_cur.   "货币码
        lt_basic_tab-cap_incr_a = ls_bp001-cap_incr_a.   "注册资本
      ENDIF.
      READ TABLE lt_umk INTO DATA(ls_umk) WITH KEY partner = ls_basic-kunnr BINARY SEARCH.
      IF sy-subrc = 0.
        lt_basic_tab-credit_sgmnt     = ls_umk-credit_sgmnt.    "信用段
        lt_basic_tab-credit_limit     = ls_umk-credit_limit.    "信用额度
        lt_basic_tab-limit_valid_date = ls_umk-limit_valid_date."有效终止日期
        lt_basic_tab-risk_class       = ls_umk-risk_class.      "风险类
        lt_basic_tab-limit_rule       = ls_umk-limit_rule.      "计算得分和信用额度的规则
        lt_basic_tab-check_rule       = ls_umk-check_rule.      "检查规则
      ENDIF.

      "销售与分销
      FREE lt_sales.
      LOOP AT lt_knvv INTO DATA(ls_knvv) WHERE kunnr = ls_basic-kunnr.
        lt_sales-kunnr   = ls_knvv-kunnr.  "客户编码
        lt_sales-vkorg   = ls_knvv-vkorg.  "销售组织
        lt_sales-vtweg   = ls_knvv-vtweg.  "分销渠道
        lt_sales-spart   = ls_knvv-spart.  "产品组
        lt_sales-vkbur   = ls_knvv-vkbur.  "销售部门
        lt_sales-vkgrp   = ls_knvv-vkgrp.  "销售组
        lt_sales-bzirk   = ls_knvv-bzirk.  "销售区域
        lt_sales-klabc   = ls_knvv-klabc.  "客户等级
        lt_sales-zywyn   = ls_knvv-eikto.  "拓展业务员
        lt_sales-waers1  = ls_knvv-waers.  "货币
        lt_sales-kalks   = ls_knvv-kalks.  "客户是否含税
        lt_sales-vsbed   = ls_knvv-vsbed.  "装运条件
        lt_sales-kzazu   = ls_knvv-kzazu.  "订单组合
        lt_sales-vwerk   = ls_knvv-vwerk.  "交货工厂
        lt_sales-inco1   = ls_knvv-inco1.  "国贸条件1
        lt_sales-inco2_l = ls_knvv-inco2_l."发运港
        lt_sales-zterm1  = ls_knvv-zterm.  "付款条件
        lt_sales-ktgrd   = ls_knvv-ktgrd.  "客户科目分配组
        lt_sales-aufsd   = ls_knvv-aufsd.  "客户订单冻结（销售范围）
        lt_sales-lifsd   = ls_knvv-lifsd.  "客户交货冻结（销售范围）
        lt_sales-faksd   = ls_knvv-faksd.  "冻结客户出具发票(销售与分销)
        READ TABLE lt_knvi INTO DATA(ls_knvi) WITH KEY kunnr = ls_basic-kunnr BINARY SEARCH.
        IF sy-subrc = 0.
          lt_sales-taxkd = ls_knvi-taxkd.  "税分类
        ENDIF.
        APPEND lt_sales.
      ENDLOOP.
      lt_basic_tab-sales = lt_sales[].

      "公司代码
      FREE lt_fi.
      LOOP AT lt_knb1 INTO DATA(ls_knb1) WHERE kunnr = ls_basic-kunnr.
        lt_fi-kunnr = ls_knb1-kunnr.   "客户编码
        lt_fi-bukrs = ls_knb1-bukrs.   "公司代码
        lt_fi-akont = ls_knb1-akont.   "统驭科目
        lt_fi-zterm = ls_knb1-zterm.   "付款条件
        lt_fi-zuawa = ls_knb1-zuawa.   "排序码
        APPEND lt_fi.
      ENDLOOP.
      lt_basic_tab-fi = lt_fi[].

      lt_basic_tab-loevm = ls_basic-loevm.
      APPEND lt_basic_tab.
    ENDLOOP.

  ENDIF.

ENDFUNCTION.
