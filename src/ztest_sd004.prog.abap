*&---------------------------------------------------------------------*
*& Report ZTEST_SD004
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_sd004.
DATA:lt_so     TYPE TABLE OF bapidlvreftosalesorder,
     ls_so     TYPE bapidlvreftosalesorder,
     lt_dn     TYPE TABLE OF bapidlvitemcreated,
     lt_return TYPE TABLE OF bapiret2,
     lv_vbeln  TYPE likp-vbeln.

DATA:BEGIN OF us_lips OCCURS 0,
       vgbel TYPE lips-vbeln,
       vgpos TYPE lips-vgpos,
       lfimg TYPE lips-lfimg,
       vrkme TYPE lips-vrkme,
       vbeln TYPE likp-vbeln,
       posnr TYPE lips-posnr,
       matnr TYPE lips-matnr,
     END OF us_lips.

*创建
ls_so-ref_doc    = us_lips-vgbel."参考凭证
ls_so-ref_item   = us_lips-vgpos."参考行
ls_so-dlv_qty    = us_lips-lfimg."实际已交货量（按销售单位）
ls_so-sales_unit = us_lips-vrkme."销售单位
APPEND ls_so TO lt_so.

CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
  IMPORTING
    delivery          = lv_vbeln
  TABLES
    sales_order_items = lt_so
    created_items     = lt_dn
    return            = lt_return.

**修改
*DATA:ls_head  TYPE bapiobdlvhdrchg,
*     ls_headx TYPE bapiobdlvhdrctrlchg,
*     lt_item  TYPE TABLE OF bapiobdlvitemchg,
*     ls_item  TYPE bapiobdlvitemchg,
*     lt_itemx TYPE TABLE OF bapiobdlvitemctrlchg,
*     ls_itemx TYPE bapiobdlvitemctrlchg.
*
*ls_head-deliv_numb = us_lips-vbeln."交货
*ls_headx-deliv_numb = us_lips-vbeln.
*
**行项目
*ls_item-deliv_numb = us_lips-vbeln. "交货单
*ls_item-deliv_item = us_lips-posnr. "交货行
*ls_item-dlv_qty    = us_lips-lfimg ."实际已交货量
*ls_item-sales_unit = us_lips-vrkme. "销售单位
**SELECT SINGLE umrez umren
**INTO (ls_item-fact_unit_nom,ls_item-fact_unit_denom)
**FROM marm
**WHERE matnr = us_lips-matnr "销售单位一定要先在主数据维护
**AND meinh = ls_item-sales_unit.
*APPEND ls_item TO lt_item.
*ls_itemx-deliv_numb = us_lips-vbeln.
*ls_itemx-deliv_item = us_lips-posnr.
*ls_itemx-chg_delqty = 'X'."修改交货数量
*APPEND ls_itemx TO lt_itemx.
*
*CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
*  EXPORTING
*    header_data    = ls_head
*    header_control = ls_headx
*    delivery       = us_lips-vbeln
*  TABLES
*    item_data      = lt_item
*    item_control   = lt_itemx
*    return         = lt_return.

TABLES likp.
PARAMETERS p_del LIKE likp-vbeln DEFAULT '8000002260'.

DATA:str_header_data    LIKE bapiobdlvhdrchg,
     str_header_control LIKE bapiobdlvhdrctrlchg.

DATA it_return TYPE STANDARD TABLE OF bapiret2  WITH HEADER LINE.
DATA it_header_deadlines TYPE STANDARD TABLE OF bapidlvdeadln WITH HEADER LINE.

DATA :item_data    LIKE bapiobdlvitemchg OCCURS 0 WITH HEADER LINE,
      item_control LIKE bapiobdlvitemctrlchg OCCURS 0 WITH HEADER LINE,
      wa_lips      LIKE lips OCCURS 0 WITH HEADER LINE.

START-OF-SELECTION.

  "修改外向交货单
  PERFORM modify1.

  "更改拣配数量
  PERFORM modify2 .

*&---------------------------------------------------------------------*
*&      Form  MODIFY1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM modify1 .
  DATA: v_16(16) TYPE c.
  DATA v_del LIKE bapiobdlvhdrchg-deliv_numb.
  SELECT SINGLE * FROM likp WHERE vbeln = p_del.

  str_header_data-deliv_numb = likp-vbeln.              "交货


  SELECT  * INTO wa_lips FROM lips WHERE vbeln = p_del.

    item_data-deliv_numb      = wa_lips-vbeln.
    item_data-deliv_item      = wa_lips-posnr.
    item_data-material        = wa_lips-matnr.
*    item_data-batch           = wa_lips-charg. "批号
    item_data-dlv_qty         = wa_lips-lfimg.  "实际已交货量（按销售单位）
*    item_data-dlv_qty_imunit  = ''.             "以仓库保管单位级的实际交货数量
    item_data-fact_unit_nom   = wa_lips-umvkz. "销售数量转换成SKU的分子(因子)
    item_data-fact_unit_denom = wa_lips-umvkn. "销售数量转换为 SKU 的值（除数）
    item_data-conv_fact   = wa_lips-umref.     "转换因子: 数量
    item_data-sales_unit  = wa_lips-vrkme.     "销售单位
*    item_data-insplot     = wa_lips-qplos.     "检验批编号
*    item_data-volume      = wa_lips-volum.     "业务量计量单位
*    item_data-stock_type  = wa_lips-insmk.     "库存
    APPEND item_data.
    CLEAR item_data.


    "*CHG_DELQTY      " 修改交货数量
    "*DEL_ITEM           " 标志：删除交货项
    "*VOLUME_FLG      " 量的确认
    "*NET_WT_FLG       " 净重的确认
    "*GROSS_WT_FLG  " 毛重的确认

    item_control-deliv_numb      = wa_lips-vbeln.
    item_control-deliv_item      = wa_lips-posnr.
    item_control-chg_delqty      = 'X'.                                          "修改交货数量
    APPEND item_control.
  ENDSELECT.


  CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
    EXPORTING
      header_data      = str_header_data
      header_control   = str_header_control
      delivery         = v_del
    TABLES
      header_deadlines = it_header_deadlines
      item_data        = item_data
      item_control     = item_control
      return           = it_return.

  IF it_return[] IS INITIAL.
    COMMIT WORK.
  ELSE.
    LOOP AT it_return.
      MESSAGE ID it_return-id TYPE it_return-type  NUMBER it_return-number.
    ENDLOOP.
  ENDIF.

ENDFORM.                                                    " MODIFY1
*&---------------------------------------------------------------------*
*&      Form  MODIFY2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM modify2  .
*& 更改拣配数量

  DATA:vbkok_wa  TYPE vbkok,
       vbpok_tab TYPE vbpok OCCURS 0 WITH HEADER LINE,
       xlips     TYPE lips  OCCURS 0 WITH HEADER LINE.

  CLEAR: vbkok_wa, vbpok_tab, xlips.

  REFRESH: vbpok_tab, xlips.

  vbkok_wa-vbeln_vl = p_del.

  SELECT * FROM lips INTO TABLE xlips
       WHERE vbeln = vbkok_wa-vbeln_vl.

  LOOP AT xlips.
    CLEAR: vbpok_tab.
    vbpok_tab-vbeln_vl = xlips-vbeln.     "交货
    vbpok_tab-posnr_vl = xlips-posnr.     "交货行
*    vbpok_tab-vbeln    = xlips-vbeln.     "后续销售和分销凭证
*    vbpok_tab-posnn    = xlips-posnr.     "销售与分销凭证的后续项目
    vbpok_tab-werks    = xlips-werks.     "工厂
    vbpok_tab-lgort    = xlips-lgort.     "库存地点
*    vbpok_tab-LIPS_DEL = 'X'.             "标志：删除交货项

    vbpok_tab-pikmg = xlips-lfimg.        "实际已交货量
    vbpok_tab-meins = xlips-meins.        "基本计量单位
    vbpok_tab-ndifm = 0.                  "拣配数量 按库存计量单位的目的地差异数量
*    vbpok_tab-taqui = ' '.                "标识：MM-WM 转储单已确认
*    vbpok_tab-charg = xlips-charg.        "批次
    vbpok_tab-matnr = xlips-matnr.        "物料
*    vbpok_tab-orpos = 0.                  "当前 OR 项目开始项目
    APPEND vbpok_tab.

  ENDLOOP.

  CALL FUNCTION 'SD_DELIVERY_UPDATE_PICKING'
    EXPORTING
      vbkok_wa  = vbkok_wa
      synchron  = 'X'
    TABLES
      vbpok_tab = vbpok_tab.

  COMMIT WORK AND WAIT.
ENDFORM.                                                    " MODIFY2
