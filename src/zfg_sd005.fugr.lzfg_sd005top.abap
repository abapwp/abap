FUNCTION-POOL zfg_sd005.                    "MESSAGE-ID ..

* INCLUDE LZFG_SD005D...                     " Local class definition
"TABLES lips.
DATA: gc_container TYPE REF TO cl_gui_custom_container,
      gc_editor    TYPE REF TO cl_gui_textedit,
      gs_likp      TYPE likp,
      gs_lips      TYPE lips.
