class ZEH_SD_SHP_DELIVERY_UPDATE definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_LE_SHP_DELIVERY_UPDATE .
protected section.
private section.
ENDCLASS.



CLASS ZEH_SD_SHP_DELIVERY_UPDATE IMPLEMENTATION.


  METHOD if_ex_le_shp_delivery_update~update_header.
    IF sy-tcode <> 'VL03N'.
      IF is_vbkok-zbstnk IS NOT INITIAL.
        MOVE is_vbkok-zbstnk TO cs_likp-zbstnk."外围系统唯一流水号
      ENDIF.
      IF is_vbkok-zzxdh IS NOT INITIAL.
        MOVE is_vbkok-zzxdh  TO cs_likp-zzxdh ."装箱单号
      ENDIF.
      IF is_vbkok-zwlgs IS NOT INITIAL.
        MOVE is_vbkok-zwlgs  TO cs_likp-zwlgs ."物流公司
      ENDIF.
      IF is_vbkok-zkddh IS NOT INITIAL.
        MOVE is_vbkok-zkddh  TO cs_likp-zkddh ."快递单号
      ENDIF.
      IF is_vbkok-zdpmc IS NOT INITIAL.
        MOVE is_vbkok-zdpmc  TO cs_likp-zdpmc ."店铺名称/客户名称
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD if_ex_le_shp_delivery_update~update_item.
    IF sy-tcode <> 'VL03N'.
      IF is_vbpok-zcpxh IS NOT INITIAL.
        MOVE is_vbpok-zcpxh    TO cs_lips-zcpxh.   "产品型号
      ENDIF.
      IF is_vbpok-zwbxtbs IS NOT INITIAL.
        MOVE is_vbpok-zwbxtbs  TO cs_lips-zwbxtbs. "平台订单号
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
