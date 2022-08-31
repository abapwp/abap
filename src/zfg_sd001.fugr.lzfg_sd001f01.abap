*----------------------------------------------------------------------*
***INCLUDE LZFG_SD001F01.
*----------------------------------------------------------------------*
*        ZFMSD_001
*&---------------------------------------------------------------------*
*& Form FRM_CREATE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*&      --> ZT_BASIC_ADD
*&---------------------------------------------------------------------*
FORM frm_create USING ls_basic_add STRUCTURE zssd001_basic.
  DATA: ls_data      TYPE  cvis_ei_extern,
        lt_data      TYPE  cvis_ei_extern_t,
        lt_return    TYPE  bapiretm,
        lt_return1   TYPE TABLE OF bapiret2,
        lv_taxnumber TYPE bapibus1006tax-taxnumber,
        ls_return    TYPE  bapireti,
        ls_partner   TYPE bus_ei_extern.
  DATA: l_address_guid     TYPE but020-guid,
        ls_addressdata_old TYPE bapibus1006_address,
        lt_bapiadtel_old   TYPE bapiadtel   OCCURS 0 WITH HEADER LINE,
        lt_bapiadfax_old   TYPE bapiadfax   OCCURS 0 WITH HEADER LINE,
        lt_bapiadttx_old   TYPE bapiadttx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadtlx_old   TYPE bapiadtlx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadsmtp_old  TYPE bapiadsmtp  OCCURS 0 WITH HEADER LINE,
        lt_return2         LIKE bapiret2   OCCURS 0 WITH HEADER LINE. "返回参数.
  DATA: lt_bapiadtel  TYPE bus_ei_bupa_telephone  OCCURS 0 WITH HEADER LINE, "电话号码的 BAPI 结构（办公地址服务）
        lt_bapiadfax  TYPE bus_ei_bupa_fax  OCCURS 0 WITH HEADER LINE , "传真号码的 BAPI 结构（办公地址服务）
        lt_bapiadsmtp TYPE bus_ei_bupa_smtp  OCCURS 0 WITH HEADER LINE . "邮箱的 BAPI 结构（办公地址服务）
  DATA: lt_partnerguid_list TYPE bu_partner_guid_t,
        ls_partnerguid_list LIKE LINE OF lt_partnerguid_list.
  DATA: lt_customer_list TYPE cvis_cust_link_t,
        ls_customer_list TYPE cvi_cust_link.
  DATA:ls_address TYPE bus_ei_bupa_address.
  DATA:lv_task(1)."操作标识
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_basic_add-kunnr
    IMPORTING
      output = ls_partner-header-object_instance-bpartner. "业务伙伴编号
  ls_partner-header-object_task = 'I'.
  ls_partner-central_data-common-data-bp_control-grouping  = ls_basic_add-ktokd."业务伙伴分组
  ls_partner-central_data-common-data-bp_control-category  = '2'.   "业务伙伴类别

  ls_data-customer-central_data-central-data-ktokd  = ls_basic_add-ktokd."客户帐户组
  ls_data-customer-central_data-central-datax-ktokd = 'X'."客户帐户组
  ls_data-customer-central_data-central-data-kukla  = ls_basic_add-kukla."客户分类
  ls_data-customer-central_data-central-datax-kukla = 'X'."客户分类
  ls_partner-central_data-common-data-bp_centraldata-title_key = '0003'." ls_basic_add-title."称谓代码
  ls_partner-central_data-common-datax-bp_centraldata-title_key = 'X'."称谓代码
  ls_partner-central_data-common-data-bp_organization-name1 = ls_basic_add-name1."组织名称 1
  ls_partner-central_data-common-datax-bp_organization-name1 = 'X'."组织名称 1
*  ls_partner-central_data-common-data-bp_organization-name2 = ls_basic_add-name2."组织名称 2
*  ls_partner-central_data-common-datax-bp_organization-name1 = 'X'."组织名称 2
  ls_partner-central_data-common-data-bp_centraldata-searchterm1  = ls_basic_add-mcod1."检索词对于匹配码搜索
  ls_partner-central_data-common-datax-bp_centraldata-searchterm1 = 'X'."检索词对于匹配码搜索
  ls_partner-central_data-common-data-bp_centraldata-searchterm2  = ls_basic_add-mcod2."匹配码搜索的搜索条件
  ls_partner-central_data-common-datax-bp_centraldata-searchterm2 = 'X'."匹配码搜索的搜索条件
*  ls_partner-central_data-common-data-bp_organization-foundationdate = ls_basic_add-found_dat."组织成立日期
*  ls_partner-central_data-common-datax-bp_organization-foundationdate = 'X'."组织成立日期
  ls_partner-central_data-address-addresses = VALUE #(
                        ( data-postal-data-street  = ls_basic_add-street"街道
                          data-postal-datax-street = 'X'"街道
                          data-postal-data-str_suppl1  = ls_basic_add-str_suppl1"街道2
                          data-postal-datax-str_suppl1 = 'X'"街道2
                          data-postal-data-str_suppl2  = ls_basic_add-str_suppl2"街道3
                          data-postal-datax-str_suppl2 = 'X'"街道3
                          data-postal-data-str_suppl3  = ls_basic_add-str_suppl3"街道 4
                          data-postal-datax-str_suppl3 = 'X'"街道3
                          data-postal-data-postl_cod1  = ls_basic_add-pstlz"邮政编码
                          data-postal-datax-postl_cod1 = 'X'"邮政编码
                          data-postal-data-city        = ls_basic_add-ort01     "城市
                          data-postal-datax-city       = 'X'"城市
                          data-postal-data-country     = ls_basic_add-land1     "国家
                          data-postal-datax-country    = 'X'"国家
                          data-postal-data-region    = ls_basic_add-regio"省份
                          data-postal-datax-region    = 'X'"省份
                          data-postal-data-langu    = ls_basic_add-spras"IS-H：功能模块长度2的一般字段
                          data-postal-datax-langu    = 'X'"IS-H：功能模块长度2的一般字段
                          data-postal-data-validfromdate    = sy-datum
                          data-postal-datax-validfromdate   = 'X'
                          data-postal-data-validtodate      = '99991231'
                          data-postal-datax-validtodate     = 'X'
                          data-postal-data-c_o_name = ls_basic_add-name_co
                          data-postal-datax-c_o_name = abap_true

    task = 'I')

    ).

  READ TABLE ls_partner-central_data-address-addresses INTO ls_address INDEX 1.
  CLEAR:lt_return2[].
  CALL FUNCTION 'BAPI_BUPA_ADDRESS_GETDETAIL'
    EXPORTING
      businesspartner = ls_partner-header-object_instance-bpartner
*     ADDRESSGUID     =
      valid_date      = sy-datum
*     RESET_BUFFER    =
*    importing
*     addressdata     = ls_address
    TABLES
      bapiadtel       = lt_bapiadtel_old
      bapiadfax       = lt_bapiadfax_old
      bapiadsmtp      = lt_bapiadsmtp_old
      return          = lt_return2.
  IF sy-subrc EQ 0.
*-----------------------------------------电话信息
    IF ls_basic_add-telf1 IS NOT INITIAL.
      CLEAR: lt_bapiadtel_old.
      READ TABLE lt_bapiadtel_old WITH KEY r_3_user = '1'.
      IF sy-subrc EQ 0.
        lt_bapiadtel-contact-task = 'U'.
      ELSE.
        CLEAR: lt_bapiadtel_old.
        READ TABLE lt_bapiadtel_old WITH KEY r_3_user = '3'.
        IF sy-subrc EQ 0 .
          lt_bapiadtel-contact-task  = 'U'.
        ELSE.
          lt_bapiadtel-contact-task  = 'I'.
        ENDIF.
      ENDIF.
      lt_bapiadtel-contact-data-r_3_user  = '1'.
      lt_bapiadtel-contact-data-telephone =  ls_basic_add-telf1.
      lt_bapiadtel-contact-datax-r_3_user = 'X'.
      lt_bapiadtel-contact-datax-telephone = 'X'.

      APPEND lt_bapiadtel TO ls_address-data-communication-phone-phone.

    ENDIF.
*-----------------------------------------

*-------------电子邮箱
    IF ls_basic_add-smtp_addr IS NOT INITIAL.
      CLEAR lt_bapiadsmtp.
      IF ls_basic_add-land1 IS INITIAL.
        ls_basic_add-land1 = 'CN'.
      ENDIF.
      lt_bapiadsmtp-contact-data-e_mail      = ls_basic_add-smtp_addr.
      lt_bapiadsmtp-contact-datax-e_mail      =  'X'.
      READ TABLE lt_bapiadsmtp_old INDEX 1.
      IF sy-subrc EQ 0.
        lt_bapiadsmtp-contact-task = 'U'.
      ELSE.
        lt_bapiadsmtp-contact-task = 'I'.
      ENDIF.
      APPEND lt_bapiadsmtp TO ls_address-data-communication-smtp-smtp.
    ENDIF.

*    IF LS_BASIC_ADD-TELF2 IS NOT INITIAL.
**      CLEAR: LT_BAPIADTEL_OLD.
**      READ TABLE LT_BAPIADTEL_OLD WITH KEY R_3_USER = '3'.
**      IF SY-SUBRC EQ 0.
**        LT_BAPIADTEL-CONTACT-TASK = 'U'.
**      ELSE.
**        CLEAR: LT_BAPIADTEL_OLD.
**        READ TABLE LT_BAPIADTEL_OLD WITH KEY R_3_USER = '1'.
**        IF SY-SUBRC EQ 0 .
**          LT_BAPIADTEL-CONTACT-TASK = 'U'.
**        ELSE.
**          LT_BAPIADTEL-CONTACT-TASK = 'I'.
**        ENDIF.
**      ENDIF.
*      LT_BAPIADTEL-CONTACT-DATA-R_3_USER  = '3'.
*      LT_BAPIADTEL-CONTACT-DATA-TELEPHONE =  LS_BASIC_ADD-TELF1.
*      LT_BAPIADTEL-CONTACT-DATAX-R_3_USER = 'X'.
*      LT_BAPIADTEL-CONTACT-DATAX-TELEPHONE = 'X'.
*      APPEND LT_BAPIADTEL TO LS_ADDRESS-DATA-COMMUNICATION-PHONE-PHONE.
*    ENDIF.
*-----------------------------------------end 电话信息
*-----------------------------------------传真信息
    IF ls_basic_add-telfx IS NOT INITIAL." OR P_ZSSD006_A-FAX_EXTENS IS NOT INITIAL.
      CLEAR lt_bapiadfax.
      IF ls_basic_add-land1 IS INITIAL.
        ls_basic_add-land1 = 'CN'.
      ENDIF.
      lt_bapiadfax-contact-data-country      = ls_basic_add-land1.
      lt_bapiadfax-contact-data-countryiso   = ls_basic_add-land1.
      lt_bapiadfax-contact-data-fax          = ls_basic_add-telfx.    "传真
      lt_bapiadfax-contact-datax-country      =  'X'.
      lt_bapiadfax-contact-datax-countryiso   =  'X'.
      lt_bapiadfax-contact-datax-fax          =  'X'.    "传真
      READ TABLE lt_bapiadfax_old INDEX 1.
      IF sy-subrc EQ 0.
        lt_bapiadfax-contact-task = 'U'.
      ELSE.
        lt_bapiadfax-contact-task = 'I'.
      ENDIF.
      APPEND lt_bapiadfax TO ls_address-data-communication-fax-fax.
    ENDIF.
    ls_address-task = 'I'.
    MODIFY ls_partner-central_data-address-addresses FROM ls_address INDEX 1 TRANSPORTING task data_key data currently_valid .
  ENDIF.
*-----------------------------------------end 传真信息

  CLEAR lv_task.
  SELECT SINGLE taxnumxl
         INTO @DATA(lv_taxnum)"获取当前客户是否存在税号
         FROM dfkkbptaxnum
        WHERE partner = @ls_basic_add-kunnr
          AND taxtype = @ls_basic_add-taxtype.
  IF ls_basic_add-taxnum <> ''.
    IF lv_taxnum IS INITIAL .
      IF sy-subrc = 0 .
        lv_task   =  'U'.
      ELSE.
        lv_task  =  'I'.
      ENDIF.
    ENDIF.
  ELSEIF lv_taxnum IS NOT INITIAL.
    lv_task  =  'D'.
  ENDIF.
  IF lv_task IS NOT INITIAL.
    ls_partner-central_data-taxnumber-taxnumbers = VALUE #( ( task = lv_task
                                                              data_key-taxtype = ls_basic_add-taxtype  "税号类别
                                                              data_key-taxnumber = ls_basic_add-taxnum"业务合作伙伴税号
                                                              data_key-taxnumxl = ls_basic_add-taxnum"业务合作伙伴税号
                                                                              ) ).
  ENDIF.

  ls_partner-central_data-role-roles = VALUE #(
                                (    task = 'I' data_key = 'FLCU00')"BP 角色
                                (    task = 'I' data_key = 'FLCU01')"BP 角色
                              ).
  ls_partner-central_data-role-time_dependent = 'X'.

*  ls_data-customer-central_data-central-data-katr1  = ls_basic_add-katr1."属性1
*  ls_data-customer-central_data-central-datax-katr1 = 'X'."属性1
*  ls_data-customer-central_data-central-data-katr2  = ls_basic_add-katr2."属性2
*  ls_data-customer-central_data-central-datax-katr2 = 'X'."属性2
*  ls_data-customer-central_data-central-data-katr3  = ls_basic_add-katr3."属性3
*  ls_data-customer-central_data-central-datax-katr3 = 'X'."属性3
*  ls_data-customer-central_data-central-data-katr4  = ls_basic_add-katr4."属性4
*  ls_data-customer-central_data-central-datax-katr4 = 'X'."属性4
*  ls_data-customer-central_data-central-data-katr5  = ls_basic_add-katr5."属性5
*  ls_data-customer-central_data-central-datax-katr5 = 'X'."属性5
*  ls_data-customer-central_data-central-data-katr6  = ls_basic_add-katr6."属性6
*  ls_data-customer-central_data-central-datax-katr6 = 'X'."属性6
*  ls_data-customer-central_data-central-data-katr7  = ls_basic_add-katr7."属性7
*  ls_data-customer-central_data-central-datax-katr7 = 'X'."属性7
*  ls_data-customer-central_data-central-data-katr8  = ls_basic_add-katr8."属性8
*  ls_data-customer-central_data-central-datax-katr8 = 'X'."属性8

  ls_data-customer-header-object_task = 'I'."是否更改
  ls_data-customer-header-object_instance-kunnr = ls_basic_add-kunnr ."客户编码

  IF ls_basic_add-ztype = 'E'.
    RETURN.
  ENDIF.
  TRY .
      ls_partner-header-object_instance-bpartnerguid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )."BAPI 的 CHAR 32 格式业务伙伴地址的全局唯一标识符
    CATCH cx_uuid_error.

  ENDTRY.
  DATA:lv_cap TYPE bapibp_ca_in_a.
  ls_partner-finserv_data-common-data-fsbp_organization-cap_incr_a = ls_basic_add-cap_incr_a."资本增长量
  IF ls_basic_add-waers IS INITIAL .
    ls_basic_add-waers = 'CNY'.
  ENDIF.
  ls_partner-finserv_data-common-data-fsbp_organization-bal_sh_cur_iso = ls_basic_add-waers."
  ls_partner-finserv_data-common-data-fsbp_organization-cntry_comp     = ls_basic_add-land1."国家
  ls_partner-finserv_data-common-data-fsbp_organization-region         = ls_basic_add-regio."地区
  ls_partner-finserv_data-common-data-fsbp_organization-comp_head      = ls_basic_add-comph."县/区
  ls_partner-finserv_data-common-data-fsbp_organization-cap_incr_y     = sy-datum+0(4)."资本增值年度
  ls_partner-finserv_data-common-datax-fsbp_organization-bal_sh_cur_iso = 'X'."
  ls_partner-finserv_data-common-datax-fsbp_organization-cap_incr_a     = 'X'."资本增长量
  ls_partner-finserv_data-common-datax-fsbp_organization-cap_incr_y     = 'X'."资本增值年度
  ls_partner-finserv_data-common-datax-fsbp_organization-cntry_comp     = 'X'."国家
  ls_partner-finserv_data-common-datax-fsbp_organization-region         = 'X'."地区
  ls_partner-finserv_data-common-datax-fsbp_organization-comp_head      = 'X'."县/区
  ls_data-partner = ls_partner.
  APPEND ls_data TO lt_data.
  "创建客户数据
  CALL FUNCTION 'CVI_EI_INBOUND_MAIN'
    EXPORTING
      i_data   = lt_data
    IMPORTING
      e_return = lt_return.

  LOOP AT lt_return INTO ls_return.

    LOOP AT ls_return-object_msg INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
      CONCATENATE ls_basic_add-zmessage  ls_msg-message INTO ls_basic_add-zmessage.
    ENDLOOP.
    IF ls_basic_add-zmessage IS NOT INITIAL.
      ls_basic_add-ztype = 'E'.
    ENDIF.
  ENDLOOP.

  IF ls_basic_add-ztype NE 'E'.
    PERFORM frm_bapi_commit.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.

  IF ls_basic_add-ztype NE 'E'.
    IF ls_basic_add-kunnr IS INITIAL.
      CLEAR lt_customer_list.
      ls_partnerguid_list = ls_partner-header-object_instance-bpartnerguid.
      APPEND ls_partnerguid_list TO lt_partnerguid_list.
      lt_customer_list = cvi_mapper=>get_instance( )->get_assigned_customers_for_bps(
                                                i_partner_guids = lt_partnerguid_list ).
      IF lt_customer_list IS NOT INITIAL.
        READ TABLE lt_customer_list INTO ls_customer_list INDEX 1 .
        IF sy-subrc EQ 0.
          ls_basic_add-kunnr = ls_customer_list-customer.
        ENDIF.
      ENDIF.
    ENDIF.
    ls_basic_add-ztype = 'S'.
    ls_basic_add-zmessage = '客户号创建成功' && ls_basic_add-kunnr && '基本视图修改成功' .
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_MODIFY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZT_BASIC_UPD
*&---------------------------------------------------------------------*
FORM frm_modify  USING ls_basic_upd STRUCTURE zssd001_basic.
  DATA: ls_data      TYPE  cvis_ei_extern,
        lt_data      TYPE  cvis_ei_extern_t,
        lt_return    TYPE  bapiretm,
        lt_return1   TYPE TABLE OF bapiret2,
        lv_taxnumber TYPE bapibus1006tax-taxnumber,
        ls_return    TYPE  bapireti,
        ls_partner   TYPE bus_ei_extern.
  DATA: l_address_guid     TYPE but020-guid,
        ls_addressdata_old TYPE bapibus1006_address,
        lt_bapiadtel_old   TYPE bapiadtel   OCCURS 0 WITH HEADER LINE,
        lt_bapiadfax_old   TYPE bapiadfax   OCCURS 0 WITH HEADER LINE,
        lt_bapiadttx_old   TYPE bapiadttx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadtlx_old   TYPE bapiadtlx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadsmtp_old  TYPE bapiadsmtp  OCCURS 0 WITH HEADER LINE,
        lt_return2         LIKE bapiret2   OCCURS 0 WITH HEADER LINE. "返回参数.
  DATA: lt_bapiadtel  TYPE bus_ei_bupa_telephone  OCCURS 0 WITH HEADER LINE, "电话号码的 BAPI 结构（办公地址服务）
        lt_bapiadfax  TYPE bus_ei_bupa_fax  OCCURS 0 WITH HEADER LINE , "传真号码的 BAPI 结构（办公地址服务）
        lt_bapiadsmtp TYPE bus_ei_bupa_smtp  OCCURS 0 WITH HEADER LINE . "邮箱的 BAPI 结构（办公地址服务）
  DATA:ls_address TYPE bus_ei_bupa_address.
  DATA:lv_task(1)."操作标识

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_basic_upd-kunnr
    IMPORTING
      output = ls_partner-header-object_instance-bpartner. "业务伙伴编号
  ls_partner-header-object_task = 'U'.
  ls_partner-central_data-common-data-bp_control-grouping  = ls_basic_upd-ktokd."业务伙伴分组
  ls_partner-central_data-common-data-bp_control-category  = '2'.   "业务伙伴类别
  SELECT SINGLE partner_guid
           FROM but000
           INTO @DATA(lv_bpartnerguid)
          WHERE partner = @ls_basic_upd-kunnr.       "业务伙伴全局唯一标识符
  ls_partner-header-object_instance-bpartnerguid = lv_bpartnerguid.      "BAPI 的 CHAR 32 格式业务伙伴地址的全局唯一标识符

  IF ls_basic_upd-zflag = 'R'.
    ls_data-customer-central_data-central-data-loevm = 'X'."主记录的集中删除标志
    ls_data-customer-central_data-central-datax-loevm = 'X'."
  ENDIF.
  ls_data-customer-central_data-central-data-ktokd  = ls_basic_upd-ktokd."客户帐户组
  ls_data-customer-central_data-central-datax-ktokd = 'X'."客户帐户组
  ls_data-customer-central_data-central-data-kukla  = ls_basic_upd-kukla."客户分类
  ls_data-customer-central_data-central-datax-kukla = 'X'."客户分类
  ls_partner-central_data-common-data-bp_centraldata-title_key = '0003'." ls_basic_upd-title."称谓代码
  ls_partner-central_data-common-datax-bp_centraldata-title_key = 'X'."称谓代码
  ls_partner-central_data-common-data-bp_organization-name1 = ls_basic_upd-name1."组织名称 1
  ls_partner-central_data-common-datax-bp_organization-name1 = 'X'."组织名称 1
  ls_partner-central_data-common-data-bp_organization-name2 = ls_basic_upd-name2."组织名称 2
  ls_partner-central_data-common-datax-bp_organization-name1 = 'X'."组织名称 2
  ls_partner-central_data-common-data-bp_centraldata-searchterm1  = ls_basic_upd-mcod1."检索词对于匹配码搜索
  ls_partner-central_data-common-datax-bp_centraldata-searchterm1 = 'X'."检索词对于匹配码搜索
  ls_partner-central_data-common-data-bp_centraldata-searchterm2  = ls_basic_upd-mcod2."匹配码搜索的搜索条件
  ls_partner-central_data-common-datax-bp_centraldata-searchterm2 = 'X'."匹配码搜索的搜索条件
  ls_partner-central_data-common-data-bp_organization-foundationdate = ls_basic_upd-found_dat."组织成立日期
  ls_partner-central_data-common-datax-bp_organization-foundationdate = 'X'."组织成立日期
  ls_partner-central_data-address-addresses = VALUE #(
                        ( data-postal-data-street  = ls_basic_upd-street"街道
                          data-postal-datax-street = 'X'"街道
                          data-postal-data-str_suppl1  = ls_basic_upd-str_suppl1"街道2
                          data-postal-datax-str_suppl1 = 'X'"街道2
                          data-postal-data-str_suppl2  = ls_basic_upd-str_suppl2"街道3
                          data-postal-datax-str_suppl2 = 'X'"街道3
                          data-postal-data-str_suppl3  = ls_basic_upd-str_suppl3"街道 4
                          data-postal-datax-str_suppl3 = 'X'"街道3
                          data-postal-data-postl_cod1  = ls_basic_upd-pstlz"邮政编码
                          data-postal-datax-postl_cod1 = 'X'"邮政编码
                          data-postal-data-city        = ls_basic_upd-ort01     "城市
                          data-postal-datax-city       = 'X'"城市
                          data-postal-data-country     = ls_basic_upd-land1     "国家
                          data-postal-datax-country    = 'X'"国家
                          data-postal-data-region    = ls_basic_upd-regio"省份
                          data-postal-datax-region    = 'X'"省份
                          data-postal-data-langu    = ls_basic_upd-spras"IS-H：功能模块长度2的一般字段
                          data-postal-datax-langu    = 'X'"IS-H：功能模块长度2的一般字段
                          data-postal-data-validfromdate    = sy-datum
                          data-postal-datax-validfromdate   = 'X'
                          data-postal-data-validtodate      = '99991231'
                          data-postal-datax-validtodate     = 'X'

                          data-postal-data-c_o_name = ls_basic_upd-name_co
                          data-postal-datax-c_o_name = abap_true

    task = '5')

    ).

  READ TABLE ls_partner-central_data-address-addresses INTO ls_address INDEX 1.
  CLEAR:lt_return2[].
  CALL FUNCTION 'BAPI_BUPA_ADDRESS_GETDETAIL'
    EXPORTING
      businesspartner = ls_partner-header-object_instance-bpartner
*     ADDRESSGUID     =
      valid_date      = sy-datum
*     RESET_BUFFER    =
*    importing
*     addressdata     = ls_address
    TABLES
      bapiadtel       = lt_bapiadtel_old
      bapiadfax       = lt_bapiadfax_old
      bapiadsmtp      = lt_bapiadsmtp_old
      return          = lt_return2.
  IF sy-subrc EQ 0.
*-----------------------------------------电话信息
    IF ls_basic_upd-telf1 IS NOT INITIAL.
      CLEAR: lt_bapiadtel_old.
      READ TABLE lt_bapiadtel_old WITH KEY r_3_user = '1'.
      IF sy-subrc EQ 0.
        lt_bapiadtel-contact-task = 'U'.
      ELSE.
        CLEAR: lt_bapiadtel_old.
        READ TABLE lt_bapiadtel_old WITH KEY r_3_user = '3'.
        IF sy-subrc EQ 0 .
          lt_bapiadtel-contact-task  = 'U'.
        ELSE.
          lt_bapiadtel-contact-task  = 'I'.
        ENDIF.
      ENDIF.
      lt_bapiadtel-contact-data-r_3_user  = '1'.
      lt_bapiadtel-contact-data-telephone =  ls_basic_upd-telf1.
      lt_bapiadtel-contact-datax-r_3_user = 'X'.
      lt_bapiadtel-contact-datax-telephone = 'X'.

      APPEND lt_bapiadtel TO ls_address-data-communication-phone-phone.

    ENDIF.
*-------------电子邮箱
    IF ls_basic_upd-smtp_addr IS NOT INITIAL.
      CLEAR lt_bapiadsmtp.
      lt_bapiadsmtp-contact-data-e_mail      = ls_basic_upd-smtp_addr.
      lt_bapiadsmtp-contact-datax-e_mail      =  'X'.
      READ TABLE lt_bapiadsmtp_old INDEX 1.
      IF sy-subrc EQ 0.
        lt_bapiadsmtp-contact-task = 'U'.
      ELSE.
        lt_bapiadsmtp-contact-task = 'I'.
      ENDIF.
      APPEND lt_bapiadsmtp TO ls_address-data-communication-smtp-smtp.
    ENDIF.
*-----------------------------------------
*    IF LS_BASIC_UPD-TELF2 IS NOT INITIAL.
*      CLEAR: LT_BAPIADTEL_OLD.
*      READ TABLE LT_BAPIADTEL_OLD WITH KEY R_3_USER = '3'.
*      IF SY-SUBRC EQ 0.
*        LT_BAPIADTEL-CONTACT-TASK = 'U'.
*      ELSE.
*        CLEAR: LT_BAPIADTEL_OLD.
*        READ TABLE LT_BAPIADTEL_OLD WITH KEY R_3_USER = '1'.
*        IF SY-SUBRC EQ 0 .
*          LT_BAPIADTEL-CONTACT-TASK = 'U'.
*        ELSE.
*          LT_BAPIADTEL-CONTACT-TASK = 'I'.
*        ENDIF.
*      ENDIF.
*      LT_BAPIADTEL-CONTACT-DATA-R_3_USER  = '3'.
*      LT_BAPIADTEL-CONTACT-DATA-TELEPHONE =  LS_BASIC_UPD-TELF2.
*      LT_BAPIADTEL-CONTACT-DATAX-R_3_USER = 'X'.
*      LT_BAPIADTEL-CONTACT-DATAX-TELEPHONE = 'X'.
*      APPEND LT_BAPIADTEL TO LS_ADDRESS-DATA-COMMUNICATION-PHONE-PHONE.
*    ENDIF.
*-----------------------------------------end 电话信息
*-----------------------------------------传真信息
    IF ls_basic_upd-telfx IS NOT INITIAL." OR P_ZSSD006_A-FAX_EXTENS IS NOT INITIAL.
      CLEAR lt_bapiadfax.
      IF ls_basic_upd-land1 IS INITIAL.
        ls_basic_upd-land1 = 'CN'.
      ENDIF.
      lt_bapiadfax-contact-data-country      = ls_basic_upd-land1.
      lt_bapiadfax-contact-data-countryiso   = ls_basic_upd-land1.
      lt_bapiadfax-contact-data-fax          = ls_basic_upd-telfx.    "传真
      lt_bapiadfax-contact-datax-country      =  'X'.
      lt_bapiadfax-contact-datax-countryiso   =  'X'.
      lt_bapiadfax-contact-datax-fax          =  'X'.    "传真
      READ TABLE lt_bapiadfax_old INDEX 1.
      IF sy-subrc EQ 0.
        lt_bapiadfax-contact-task = 'U'.
      ELSE.
        lt_bapiadfax-contact-task = 'I'.
      ENDIF.
      APPEND lt_bapiadfax TO ls_address-data-communication-fax-fax.
    ENDIF.

    MODIFY ls_partner-central_data-address-addresses FROM ls_address INDEX 1 TRANSPORTING task data_key data currently_valid .
  ENDIF.
*-----------------------------------------end 传真信息
  CLEAR lv_task.
  SELECT SINGLE taxnumxl
         INTO @DATA(lv_taxnum)"获取当前客户是否存在税号
         FROM dfkkbptaxnum
        WHERE partner = @ls_basic_upd-kunnr.
  IF ls_basic_upd-taxnum <> ''.
    IF lv_taxnum IS INITIAL .
      lv_task   =  'I'.
    ELSE.
      lv_task  =  'U'.
    ENDIF.
  ELSEIF lv_taxnum IS NOT INITIAL.
    lv_task  =  'D'.
  ENDIF.
  IF lv_task IS NOT INITIAL.
    ls_partner-central_data-taxnumber-taxnumbers = VALUE #( ( task = lv_task
                                                              data_key-taxtype = ls_basic_upd-taxtype  "税号类别
                                                              data_key-taxnumber = ls_basic_upd-taxnum"业务合作伙伴税号
                                                              data_key-taxnumxl = ls_basic_upd-taxnum"业务合作伙伴税号
                                                                              ) ).
  ENDIF.

  ls_partner-central_data-role-roles = VALUE #(
                                (    task = 'U' data_key = 'FLCU00')"BP 角色
                                (    task = 'U' data_key = 'FLCU01')"BP 角色
                              ).
  ls_partner-central_data-role-time_dependent = 'X'.

*  ls_data-customer-central_data-central-data-katr1  = ls_basic_upd-katr1."属性1
*  ls_data-customer-central_data-central-datax-katr1 = 'X'."属性1
*  ls_data-customer-central_data-central-data-katr2  = ls_basic_upd-katr2."属性2
*  ls_data-customer-central_data-central-datax-katr2 = 'X'."属性2
*  ls_data-customer-central_data-central-data-katr3  = ls_basic_upd-katr3."属性3
*  ls_data-customer-central_data-central-datax-katr3 = 'X'."属性3
*  ls_data-customer-central_data-central-data-katr4  = ls_basic_upd-katr4."属性4
*  ls_data-customer-central_data-central-datax-katr4 = 'X'."属性4
*  ls_data-customer-central_data-central-data-katr5  = ls_basic_upd-katr5."属性5
*  ls_data-customer-central_data-central-datax-katr5 = 'X'."属性5
*  ls_data-customer-central_data-central-data-katr6  = ls_basic_upd-katr6."属性6
*  ls_data-customer-central_data-central-datax-katr6 = 'X'."属性6
*  ls_data-customer-central_data-central-data-katr7  = ls_basic_upd-katr7."属性7
*  ls_data-customer-central_data-central-datax-katr7 = 'X'."属性7
*  ls_data-customer-central_data-central-data-katr8  = ls_basic_upd-katr8."属性8
*  ls_data-customer-central_data-central-datax-katr8 = 'X'."属性8

  ls_data-customer-header-object_task = 'U'."是否更改
  ls_data-customer-header-object_instance-kunnr = ls_basic_upd-kunnr ."客户编码

  ls_partner-finserv_data-common-data-fsbp_organization-cap_incr_a = ls_basic_upd-cap_incr_a."资本增长量
  IF ls_basic_upd-waers IS INITIAL .
    ls_basic_upd-waers = 'CNY'.
  ENDIF.
  ls_partner-finserv_data-common-data-fsbp_organization-bal_sh_cur_iso  = ls_basic_upd-waers."货币代码
  ls_partner-finserv_data-common-data-fsbp_organization-cap_incr_y      = sy-datum+0(4)."资本增值年度
  ls_partner-finserv_data-common-data-fsbp_organization-cntry_comp    = ls_basic_upd-land1."国家
  ls_partner-finserv_data-common-data-fsbp_organization-region          = ls_basic_upd-regio."地区
  ls_partner-finserv_data-common-data-fsbp_organization-comp_head       = ls_basic_upd-comph."县/区
  ls_partner-finserv_data-common-datax-fsbp_organization-bal_sh_cur_iso = 'X'."货币代码
  ls_partner-finserv_data-common-datax-fsbp_organization-cap_incr_a     = 'X'."资本增长量
  ls_partner-finserv_data-common-datax-fsbp_organization-cap_incr_y     = 'X'."资本增值年度
  ls_partner-finserv_data-common-datax-fsbp_organization-cntry_comp     = 'X'."县/区
  ls_partner-finserv_data-common-datax-fsbp_organization-region         = 'X'."县/区
  ls_partner-finserv_data-common-datax-fsbp_organization-comp_head      = 'X'."县/区
  ls_data-partner = ls_partner.
  APPEND ls_data TO lt_data.
  IF ls_basic_upd-ztype = 'E'.
    RETURN.
  ENDIF.
  "创建客户数据
  CALL FUNCTION 'CVI_EI_INBOUND_MAIN'
    EXPORTING
      i_data   = lt_data
    IMPORTING
      e_return = lt_return.

  LOOP AT lt_return INTO ls_return.

    LOOP AT ls_return-object_msg INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
      CONCATENATE ls_basic_upd-zmessage  ls_msg-message INTO ls_basic_upd-zmessage.
    ENDLOOP.
    IF sy-subrc = 0.
      ls_basic_upd-ztype = 'E'.
    ENDIF.
  ENDLOOP.

  IF ls_basic_upd-ztype NE 'E'.
    PERFORM frm_bapi_commit.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.

  IF ls_basic_upd-ztype NE 'E'.
    ls_basic_upd-ztype = 'S'.
    IF ls_basic_upd-zflag = 'U'.
      ls_basic_upd-zmessage = '客户修改成功！'.
    ELSEIF ls_basic_upd-zflag = 'R'.
      ls_basic_upd-zmessage = '客户删除标记成功！'.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CREATE_FI
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZT_FI_DATA
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form FRM_CREATE_FI
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_create_fi USING ls_fi_data STRUCTURE zssd001_fi.
  DATA: ls_data    TYPE  cvis_ei_extern,
        lt_data    TYPE  cvis_ei_extern_t,
        lt_return  TYPE  bapiretm,
        ls_return  TYPE  bapireti,
        ls_partner TYPE bus_ei_extern.
  DATA:ls_company TYPE cmds_ei_company.
  DATA: l_address_guid     TYPE but020-guid,
        ls_addressdata_old TYPE bapibus1006_address,
        lt_bapiadtel_old   TYPE bapiadtel   OCCURS 0 WITH HEADER LINE,
        lt_bapiadfax_old   TYPE bapiadfax   OCCURS 0 WITH HEADER LINE,
        lt_bapiadttx_old   TYPE bapiadttx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadtlx_old   TYPE bapiadtlx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadsmtp_old  TYPE bapiadsmtp  OCCURS 0 WITH HEADER LINE,
        lt_return2         LIKE bapiret2   OCCURS 0 WITH HEADER LINE. "返回参数.
  DATA: lt_bapiadtel TYPE bus_ei_bupa_telephone  OCCURS 0 WITH HEADER LINE, "电话号码的 BAPI 结构（办公地址服务）
        lt_bapiadfax TYPE bus_ei_bupa_fax  OCCURS 0 WITH HEADER LINE . "传真号码的 BAPI 结构（办公地址服务）
  DATA:ls_address TYPE bus_ei_bupa_address.
  DATA:lv_task(1)."操作标识

  "统驭科目
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_fi_data-akont
    IMPORTING
      output = ls_fi_data-akont.
  IF  ls_fi_data-zflag = 'U'
  OR ls_fi_data-zflag = 'D'.
    ls_company-task = 'U'.
  ELSE.
    ls_company-task = 'I'.
  ENDIF.

*&----------------拓展公司代码---------------------
  DATA:BEGIN OF lt_itab OCCURS 0,
         zgnbs TYPE c,
         bukrs TYPE zssd001_fi-bukrs,
       END OF lt_itab.
  lt_itab-zgnbs = 'N'."国内公司代码
  lt_itab-bukrs = '3101'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'N'.
  lt_itab-bukrs = '3102'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'N'.
  lt_itab-bukrs = '3103'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'N'.
  lt_itab-bukrs = '3104'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'W'."国外公司代码
  lt_itab-bukrs = '3201'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'W'.
  lt_itab-bukrs = '3202'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'W'.
  lt_itab-bukrs = '3203'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'W'.
  lt_itab-bukrs = '3204'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'W'.
  lt_itab-bukrs = '3205'.
  APPEND lt_itab .
  lt_itab-zgnbs = 'W'.
  lt_itab-bukrs = '3206'.
  APPEND lt_itab .
*&-------------------------------------------------

  ls_company-data_key-bukrs = ls_fi_data-bukrs."公司代码
  ls_company-data-akont = ls_fi_data-akont."总帐中的统驭科目
  ls_company-datax-akont = 'X'."总帐中的统驭科目
  ls_company-data-zterm = ls_fi_data-zterm."收付条件代码
  ls_company-datax-zterm = 'X'."收付条件代码
  ls_company-data-zuawa = ls_fi_data-zuawa."根据分配号排序代码
  ls_company-datax-zuawa = 'X'."根据分配号排序代码
  IF ls_fi_data-zflag = 'D'.
    ls_company-data-sperr = 'X'."对公司代码过帐冻结
    ls_company-datax-sperr = 'X'.
  ENDIF.
  IF ls_fi_data-zflag = 'R'.
    ls_company-data-loevm = 'X'."主记录删除标记(公司代码级)
    ls_company-datax-loevm = 'X'."主记录删除标记(公司代码级)
  ENDIF.
*  ls_company-data-nodel = ls_fi_data-nodel."主记录的删除冻结（公司代码级）
*  ls_company-datax-nodel = 'X'.     "主记录的删除冻结（公司代码级）
*  ls_company-data-altkn = ls_fi_data-altkn."①  先前账户号码
*  ls_company-datax-altkn = 'X'.     "①  先前账户号码
  APPEND ls_company TO ls_data-customer-company_data-company.

*&--------------------------------------------------------------------
  IF ls_fi_data-bukrs = '3101' OR ls_fi_data-bukrs = '3102'
  OR ls_fi_data-bukrs = '3103' OR ls_fi_data-bukrs = '3104'.

    LOOP AT lt_itab WHERE bukrs NE ls_fi_data-bukrs AND zgnbs = 'N'.
      ls_company-data_key-bukrs = lt_itab-bukrs."公司代码
      APPEND ls_company TO ls_data-customer-company_data-company.
    ENDLOOP.

  ELSEIF ls_fi_data-bukrs = '3201' OR ls_fi_data-bukrs = '3202'
       OR ls_fi_data-bukrs = '3203' OR ls_fi_data-bukrs = '3204'
       OR ls_fi_data-bukrs = '3205' OR ls_fi_data-bukrs = '3206'.

    LOOP AT lt_itab WHERE bukrs NE ls_fi_data-bukrs AND zgnbs = 'W'.
      ls_company-data_key-bukrs = lt_itab-bukrs."公司代码
      APPEND ls_company TO ls_data-customer-company_data-company.
    ENDLOOP.
  ENDIF.
  IF ls_fi_data-zflag = 'I' .
    SELECT kunnr,bukrs INTO TABLE @DATA(lt_knb1) FROM knb1
      WHERE kunnr = @ls_fi_data-kunnr.
    LOOP AT lt_knb1 INTO DATA(ls_knb1).
      DELETE ls_data-customer-company_data-company WHERE data_key-bukrs = ls_knb1-bukrs.
    ENDLOOP.
  ENDIF.
*&-------------------------------------------------------------

  ls_data-customer-header-object_task = 'U'."是否更改
  ls_data-customer-header-object_instance-kunnr = ls_fi_data-kunnr ."客户编码

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_fi_data-kunnr
    IMPORTING
      output = ls_partner-header-object_instance-bpartner. "业务伙伴编号

  ls_partner-header-object_task = 'U'.
  SELECT SINGLE partner_guid
           FROM but000
           INTO @DATA(lv_bpartnerguid)
          WHERE partner = @ls_fi_data-kunnr.       "业务伙伴全局唯一标识符
  ls_partner-header-object_instance-bpartnerguid = lv_bpartnerguid.      "BAPI 的 CHAR 32 格式业务伙伴地址的全局唯一标识符
  ls_data-partner = ls_partner.
  APPEND ls_data TO lt_data.
  CALL FUNCTION 'CVI_EI_INBOUND_MAIN'
    EXPORTING
      i_data   = lt_data
    IMPORTING
      e_return = lt_return.
  LOOP AT lt_return INTO ls_return.

    LOOP AT ls_return-object_msg INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
      CONCATENATE ls_fi_data-zmessage  ls_msg-message INTO ls_fi_data-zmessage.
    ENDLOOP.
    IF sy-subrc = 0.
      ls_fi_data-ztype = 'E'.
    ENDIF.
  ENDLOOP.

  IF ls_fi_data-ztype NE 'E'.
    PERFORM frm_bapi_commit.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.

  IF ls_fi_data-ztype NE 'E'.
    ls_fi_data-ztype = 'S'.
    IF ls_fi_data-zflag = 'D'.
      ls_fi_data-zmessage = '财务视图冻结成功 ! '.
    ELSEIF ls_fi_data-zflag = 'C'.
      ls_fi_data-zmessage = '财务视图取消冻结成功 ! '.
    ELSEIF ls_fi_data-zflag = 'R'.
      ls_fi_data-zmessage = '财务视图删除标记成功 ! '.
    ELSE.
      ls_fi_data-zmessage = '财务视图创建/修改成功 ! '.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_CREATE_SALES
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_create_sales USING ls_sales_data STRUCTURE zssd001_sales
                              ls_kna1 STRUCTURE kna1.

  DATA: ls_data    TYPE  cvis_ei_extern,
        lt_data    TYPE  cvis_ei_extern_t,
        lt_return  TYPE  bapiretm,
        ls_return  TYPE  bapireti,
        ls_partner TYPE bus_ei_extern.
  DATA:ls_sales TYPE cmds_ei_sales.
  DATA: l_address_guid     TYPE but020-guid,
        ls_addressdata_old TYPE bapibus1006_address,
        lt_bapiadtel_old   TYPE bapiadtel   OCCURS 0 WITH HEADER LINE,
        lt_bapiadfax_old   TYPE bapiadfax   OCCURS 0 WITH HEADER LINE,
        lt_bapiadttx_old   TYPE bapiadttx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadtlx_old   TYPE bapiadtlx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadsmtp_old  TYPE bapiadsmtp  OCCURS 0 WITH HEADER LINE,
        lt_return2         LIKE bapiret2   OCCURS 0 WITH HEADER LINE. "返回参数.
  DATA: lt_bapiadtel TYPE bus_ei_bupa_telephone  OCCURS 0 WITH HEADER LINE, "电话号码的 BAPI 结构（办公地址服务）
        lt_bapiadfax TYPE bus_ei_bupa_fax  OCCURS 0 WITH HEADER LINE . "传真号码的 BAPI 结构（办公地址服务）
  DATA:ls_address TYPE bus_ei_bupa_address.
  DATA:lv_task(1)."操作标识
  DATA: tline LIKE TABLE OF tline WITH HEADER LINE.
  DATA:ls_text TYPE cvis_ei_text.
  IF  ls_sales_data-zflag = 'U'
   OR ls_sales_data-zflag = 'D'.
    ls_sales-task = 'U'.
  ELSE.
    ls_sales-task = 'I'.
  ENDIF.

*&-------------------拓展销售公司----------------------------
  DATA:BEGIN OF lt_vkorg OCCURS 0,
         zgnbs TYPE c,
         vkorg TYPE zssd001_sales-vkorg,
       END OF lt_vkorg.
  lt_vkorg-zgnbs = 'N'."国内销售公司
  lt_vkorg-vkorg = '3101'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'N'.
  lt_vkorg-vkorg = '3102'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'N'.
  lt_vkorg-vkorg = '3103'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'N'.
  lt_vkorg-vkorg = '3104'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'W'."国外销售公司
  lt_vkorg-vkorg = '3201'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'W'.
  lt_vkorg-vkorg = '3202'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'W'.
  lt_vkorg-vkorg = '3203'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'W'.
  lt_vkorg-vkorg = '3204'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'W'.
  lt_vkorg-vkorg = '3205'.
  APPEND lt_vkorg .
  lt_vkorg-zgnbs = 'W'.
  lt_vkorg-vkorg = '3206'.
  APPEND lt_vkorg .
*&-------------------------------------------------------------
  ls_sales-data_key-vkorg = ls_sales_data-vkorg."销售组织
  ls_sales-data_key-vtweg = ls_sales_data-vtweg."分销渠道
  ls_sales-data_key-spart = ls_sales_data-spart."产品组
  "销售办公室
  ls_sales-data-vkbur  = ls_sales_data-vkbur.
  ls_sales-datax-vkbur = 'X'.
  "销售组
  ls_sales-data-vkgrp  = ls_sales_data-vkgrp.
  ls_sales-datax-vkgrp = 'X'.
  "客户组
  ls_sales-data-kdgrp  = ls_sales_data-kdgrp.
  ls_sales-datax-kdgrp = 'X'.
  "装运条件
  ls_sales-data-vsbed  = ls_sales_data-vsbed.
  ls_sales-datax-vsbed = 'X'.

  "帐户分配组
  ls_sales-data-ktgrd  = ls_sales_data-ktgrd.
  ls_sales-datax-ktgrd = 'X'.
  "付款条件
  ls_sales-data-zterm  = ls_sales_data-zterm.
  ls_sales-datax-zterm = 'X'.

  "价格组
  ls_sales-data-konda  = ls_sales_data-konda.
  ls_sales-datax-konda = 'X'.
  "客户分类
  ls_sales-data-kalks  = ls_sales_data-kalks.
  ls_sales-datax-kalks = 'X'.
  "币种
  ls_sales-data-waers    = ls_sales_data-waers.
  ls_sales-datax-waers   = 'X'.
  ls_sales-data-inco1    = ls_sales_data-inco1.
  ls_sales-datax-inco1   = 'X'.
  ls_sales-data-inco2_l  = ls_sales_data-inco2_l.
  ls_sales-datax-inco2_l = 'X'.
  ls_sales-data-inco2    = ls_sales_data-inco2_l.
  ls_sales-datax-inco2   = 'X'.

  ls_sales-data-kvgr1  = ls_sales_data-kvgr1.  "客户组1
  ls_sales-datax-kvgr1 = 'X'.
  ls_sales-data-kvgr2  = ls_sales_data-kvgr2.  "客户组2
  ls_sales-datax-kvgr2 = 'X'.
  ls_sales-data-kvgr3  = ls_sales_data-kvgr3.  "客户组3
  ls_sales-datax-kvgr3 = 'X'.
  ls_sales-data-kvgr4  = ls_sales_data-kvgr4.  "客户组4
  ls_sales-datax-kvgr4 = 'X'.
  ls_sales-data-kvgr5  = ls_sales_data-kvgr5.  "客户组5
  ls_sales-datax-kvgr5 = 'X'.

*  ls_sales-data-eikto  = ls_sales_data-eikto.  " 旧系统客户编码（必填）
*  ls_sales-datax-eikto = 'X'.

  ls_sales-data-pltyp  = ls_sales_data-pltyp.  " 价格清单类型
  ls_sales-datax-pltyp = 'X'.

  ls_sales-data-kzazu  = ls_sales_data-kzazu.  " 订单组合标识
  ls_sales-datax-kzazu = 'X'.
  ls_sales-data-vwerk  = ls_sales_data-vwerk.  " 交货工厂 (自有或外部)
  ls_sales-datax-vwerk = 'X'.

  ls_sales-data-bzirk  = ls_sales_data-bzirk.  "销售地区
  ls_sales-datax-bzirk = 'X'.
  ls_sales-data-lprio  = '02'.  "②  交货优先级
  ls_sales-datax-lprio = 'X'.

  ls_sales-data-klabc  = ls_sales_data-klabc.  "客户等级
  ls_sales-datax-klabc = 'X'.

  ls_sales-data-konda  = '01'.  "客户价格组
  ls_sales-datax-konda = 'X'.

  ls_sales-data-awahr  = '100'.
  ls_sales-datax-awahr = 'X'.

  ls_sales-data-eikto  = ls_sales_data-zywyn."拓展业务员
  ls_sales-datax-eikto = 'X'.

  IF ls_sales_data-zflag = 'D'.
    ls_sales-data-aufsd  = '01'.  " 客户订单冻结（销售范围）
    ls_sales-datax-aufsd = 'X'.
    ls_sales-data-lifsd  = '01'.  " 客户交货冻结（销售范围）
    ls_sales-datax-lifsd = 'X'.
    ls_sales-data-faksd  = '01'.  " 冻结客户出具发票( 销售和分销 )
    ls_sales-datax-faksd = 'X'.
  ENDIF.

  "客户税分类
  CLEAR lv_task.
  SELECT SINGLE COUNT(*)
                 FROM knvi
                WHERE kunnr = ls_sales_data-kunnr
                  AND aland = 'CN'
                  AND tatyp = 'MWST'.
  IF sy-subrc = 0.
    lv_task = 'U'.
  ELSE.
    lv_task = 'I'.
  ENDIF.
  ls_data-customer-central_data-tax_ind-tax_ind = VALUE #(
                    ( task = lv_task  data_key-aland = 'CN' data_key-tatyp = 'MWST'   data-taxkd = ls_sales_data-taxkd datax-taxkd = 'X' )
                                                          ).
  APPEND ls_sales TO ls_data-customer-sales_data-sales.


  IF ls_sales_data-vkorg = '3101' OR ls_sales_data-vkorg = '3102'
    OR ls_sales_data-vkorg = '3103' OR ls_sales_data-vkorg = '3104'.

    LOOP AT lt_vkorg WHERE vkorg NE ls_sales_data-vkorg AND zgnbs = 'N'.
      ls_sales-data_key-vkorg = lt_vkorg-vkorg."销售组织
      APPEND ls_sales TO ls_data-customer-sales_data-sales.
    ENDLOOP.

  ELSEIF ls_sales_data-vkorg = '3201' OR ls_sales_data-vkorg = '3202'
      OR ls_sales_data-vkorg = '3203' OR ls_sales_data-vkorg = '3204'
      OR ls_sales_data-vkorg = '3205' OR ls_sales_data-vkorg = '3206'.

    LOOP AT lt_vkorg WHERE vkorg NE ls_sales_data-vkorg AND zgnbs = 'W'.
      ls_sales-data_key-vkorg = lt_vkorg-vkorg."销售组织
      APPEND ls_sales TO ls_data-customer-sales_data-sales.
    ENDLOOP.

  ENDIF.

  IF ls_sales_data-zflag = 'I' .
    SELECT kunnr,vkorg INTO TABLE @DATA(lt_knvv) FROM knvv
      WHERE kunnr = @ls_sales_data-kunnr.
    LOOP AT lt_knvv INTO DATA(ls_knvv).
      DELETE ls_data-customer-sales_data-sales WHERE data_key-vkorg = ls_knvv-vkorg.
    ENDLOOP.
  ENDIF.
*&-------------------------------------------------------------

  ls_data-customer-header-object_task = 'U'."是否更改
  ls_data-customer-header-object_instance-kunnr = ls_sales_data-kunnr ."客户编码

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_sales_data-kunnr
    IMPORTING
      output = ls_partner-header-object_instance-bpartner. "业务伙伴编号
  ls_partner-header-object_task = 'U'.
  SELECT SINGLE partner_guid
           FROM but000
           INTO @DATA(lv_bpartnerguid)
          WHERE partner = @ls_sales_data-kunnr.       "业务伙伴全局唯一标识符
  ls_partner-header-object_instance-bpartnerguid = lv_bpartnerguid.      "BAPI 的 CHAR 32 格式业务伙伴地址的全局唯一标识符
  ls_data-partner = ls_partner.
  APPEND ls_data TO lt_data.
  CALL FUNCTION 'CVI_EI_INBOUND_MAIN'
    EXPORTING
      i_data   = lt_data
    IMPORTING
      e_return = lt_return.
  LOOP AT lt_return INTO ls_return.

    LOOP AT ls_return-object_msg INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
      CONCATENATE ls_sales_data-zmessage  ls_msg-message INTO ls_sales_data-zmessage.
    ENDLOOP.
    IF sy-subrc = 0.
      ls_sales_data-ztype = 'E'.
    ENDIF.
  ENDLOOP.

  IF ls_sales_data-ztype NE 'E'.
    PERFORM frm_bapi_commit.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.

  IF ls_sales_data-ztype NE 'E'.
    ls_sales_data-ztype = 'S'.
    IF ls_sales_data-zflag = 'D'.
      ls_sales_data-zmessage = '销售视图冻结成功 ! '.
    ELSEIF ls_sales_data-zflag = 'R'.
      ls_sales_data-zmessage = '销售视图删除标记成功 ! '.
    ELSE.
      ls_sales_data-zmessage = '销售视图创建/修改成功 ! '.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_create_zukm
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- ZT_UKM_DATA
*&---------------------------------------------------------------------*
FORM frm_create_zukm  CHANGING ls_ukm_data TYPE zssd001_ukm.

  DATA: ls_data    TYPE  cvis_ei_extern,
        lt_data    TYPE  cvis_ei_extern_t,
        lt_return  TYPE  bapiretm,
        ls_return  TYPE  bapireti,
        ls_partner TYPE bus_ei_extern.
  DATA:ls_sales TYPE cmds_ei_sales.
  DATA: l_address_guid     TYPE but020-guid,
        ls_addressdata_old TYPE bapibus1006_address,
        lt_bapiadtel_old   TYPE bapiadtel   OCCURS 0 WITH HEADER LINE,
        lt_bapiadfax_old   TYPE bapiadfax   OCCURS 0 WITH HEADER LINE,
        lt_bapiadttx_old   TYPE bapiadttx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadtlx_old   TYPE bapiadtlx   OCCURS 0 WITH HEADER LINE,
        lt_bapiadsmtp_old  TYPE bapiadsmtp  OCCURS 0 WITH HEADER LINE,
        lt_return2         LIKE bapiret2   OCCURS 0 WITH HEADER LINE. "返回参数.
  DATA: lt_bapiadtel TYPE bus_ei_bupa_telephone  OCCURS 0 WITH HEADER LINE, "电话号码的 BAPI 结构（办公地址服务）
        lt_bapiadfax TYPE bus_ei_bupa_fax  OCCURS 0 WITH HEADER LINE . "传真号码的 BAPI 结构（办公地址服务）
  DATA:ls_address TYPE bus_ei_bupa_address.
  DATA:lv_task(1)."操作标识

  ls_partner-central_data-role-roles = VALUE #(
                                (    task = ls_ukm_data-zflag data_key = 'UKM000')"BP 角色
                              ).

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_ukm_data-kunnr
    IMPORTING
      output = ls_ukm_data-kunnr.
  ls_partner-header-object_instance-bpartner = ls_ukm_data-kunnr. "业务伙伴编号
  ls_partner-header-object_task = 'U'.
  SELECT SINGLE partner_guid
           FROM but000
           INTO @DATA(lv_bpartnerguid)
          WHERE partner = @ls_ukm_data-kunnr.       "业务伙伴全局唯一标识符
  ls_partner-header-object_instance-bpartnerguid = lv_bpartnerguid.      "BAPI 的 CHAR 32 格式业务伙伴地址的全局唯一标识符
  ls_partner-ukmbp_data-profile-data-limit_rule = ls_ukm_data-limit_rule.
  ls_partner-ukmbp_data-profile-datax-limit_rule = 'X'.
  ls_partner-ukmbp_data-profile-data-risk_class = ls_ukm_data-risk_class.
  ls_partner-ukmbp_data-profile-datax-risk_class = 'X'.
  ls_partner-ukmbp_data-profile-data-check_rule = ls_ukm_data-check_rule.
  ls_partner-ukmbp_data-profile-datax-check_rule = 'X'.
  SELECT SINGLE partner INTO ls_ukm_data-kunnr FROM ukmbp_cms_sgm
    WHERE partner = ls_ukm_data-kunnr
      AND credit_sgmnt = ls_ukm_data-credit_sgmnt.
  IF sy-subrc = 0.
    DATA(lv_sgmnt_flag) = 'U'.
  ELSE.
    lv_sgmnt_flag = 'I'.
  ENDIF.
  IF ls_ukm_data-credit_sgmnt IS INITIAL.
    ls_ukm_data-credit_sgmnt = '0000'.
  ENDIF.
  ls_partner-ukmbp_data-segments-segments =  VALUE #( ( task = lv_sgmnt_flag
                                                         data_key-partner = ls_ukm_data-kunnr
                                                         data_key-credit_sgmnt = ls_ukm_data-credit_sgmnt
                                                         data-credit_limit = ls_ukm_data-credit_limit
                                                         datax-credit_limit = 'X'
                                                         data-limit_valid_date = ls_ukm_data-limit_valid_date
                                                         datax-limit_valid_date = 'X'
                                                          ) ).

  ls_data-partner = ls_partner.
  APPEND ls_data TO lt_data.
  CALL FUNCTION 'CVI_EI_INBOUND_MAIN'
    EXPORTING
      i_data   = lt_data
    IMPORTING
      e_return = lt_return.
  LOOP AT lt_return INTO ls_return.

    LOOP AT ls_return-object_msg INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
      CONCATENATE ls_ukm_data-zmessage  ls_msg-message INTO ls_ukm_data-zmessage.
    ENDLOOP.
    IF sy-subrc = 0.
      ls_ukm_data-ztype = 'E'.
    ENDIF.
  ENDLOOP.

  IF ls_ukm_data-ztype NE 'E'.
    PERFORM frm_bapi_commit.
    ls_ukm_data-ztype = 'S'.
    ls_ukm_data-zmessage = '创建/修改成功'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.
ENDFORM.
FORM frm_bapi_commit .
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.
ENDFORM.
