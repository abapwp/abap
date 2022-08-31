*&---------------------------------------------------------------------*
*& Report ZJOBSD001
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zjobsd001.

TYPES:BEGIN OF token_data,
        access_token  TYPE string,
        refresh_token TYPE string,
        expires_in    TYPE string,
      END OF token_data.
DATA:BEGIN OF ty_token,
       code TYPE string,
       msg  TYPE string,
       data TYPE token_data.
DATA:END OF ty_token.
DATA : ls_token LIKE ty_token.
DATA:BEGIN OF ty_body,
       sid TYPE string,
     END OF ty_body.
DATA:lt_body LIKE TABLE OF ty_body,
     ls_body LIKE ty_body.
SELECTION-SCREEN BEGIN OF BLOCK b1.
    PARAMETERS:p_url TYPE string DEFAULT 'https://openapisandbox.lingxing.com'.
    PARAMETERS:p_uri TYPE string DEFAULT '/erp/sc/routing/order/Order/getOrderList'.
SELECTION-SCREEN END OF BLOCK b1.




CONSTANTS:cs_url TYPE string VALUE 'https://openapisandbox.lingxing.com'.
CONSTANTS:appId TYPE string VALUE 'ak_Sk0qpgngZ0yAL'.
CONSTANTS:appSecret TYPE string VALUE 'AXUlEoZzwTOM2KqosCOaIw=='.
DATA:lv_uri TYPE string VALUE '/api/auth-server/oauth/access-token'.
DATA:json_result TYPE string.
DATA:lv_token TYPE string.

CALL FUNCTION 'ZFM_CALL_HTTP_LX'
  EXPORTING
    iv_url        = cs_url
    iv_uri        = lv_uri
    iv_ifname     = 'ZIF001' "获取token
    iv_appid      = appid
    iv_appsecret  = appsecret
*   IV_TOKEN      =
  IMPORTING
    json          = json_result
* TABLES
*   IT_TABLE      =
  EXCEPTIONS
    client_failed = 1
    error_method  = 2
    send_error    = 3
    receive_error = 4
    token_miss    = 5
    OTHERS        = 6.
IF sy-subrc <> 0.
  MESSAGE s001(00) WITH '接口调用失败' sy-datum sy-uzeit.
  EXIT.
ENDIF.
/ui2/cl_json=>deserialize(
    EXPORTING
      json = json_result
    CHANGING
      data = ls_token
).
IF ls_token-code EQ '200'.
  lv_token = ls_token-data-access_token.
ELSE.
  MESSAGE s001(00) WITH 'TOKEN获取失败' sy-datum sy-uzeit.
  EXIT.
ENDIF.
lv_uri = '/erp/sc/routing/order/Order/getOrderList'.
ls_body-sid = '196'.
APPEND ls_body TO lt_body.
CALL FUNCTION 'ZFM_CALL_HTTP_LX'
  EXPORTING
    iv_url        = cs_url
    iv_uri        = lv_uri
    iv_ifname     = 'ZIF002' "获取订单列表
    iv_appid      = appid
    iv_appsecret  = appsecret
    iv_token      = lv_token
  IMPORTING
    json          = json_result
  TABLES
    it_table      = lt_body
  EXCEPTIONS
    client_failed = 1
    error_method  = 2
    send_error    = 3
    receive_error = 4
    token_miss    = 5
    OTHERS        = 6.
IF sy-subrc <> 0.
  MESSAGE s001(00) WITH '接口调用失败' sy-datum sy-uzeit.
  EXIT.
ENDIF.
