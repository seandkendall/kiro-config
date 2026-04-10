---
name: sap-abap-patterns
description: SAP ABAP code patterns for ALV reports, BAPI calls, data migration, CDS views, ABAP Unit tests. Use when writing or reviewing ABAP code.
---

# SAP ABAP Patterns

## ALV Report Template

```abap
REPORT z_my_report.
TABLES: vbak.
SELECT-OPTIONS: s_vbeln FOR vbak-vbeln.

TYPES: BEGIN OF ty_row,
         vbeln TYPE vbak-vbeln,
         erdat TYPE vbak-erdat,
         netwr TYPE vbak-netwr,
       END OF ty_row.

DATA(orders) = VALUE ty_row( ).
SELECT vbeln erdat netwr FROM vbak INTO TABLE @orders WHERE vbeln IN @s_vbeln.
IF sy-subrc <> 0.
  MESSAGE 'No data found' TYPE 'S' DISPLAY LIKE 'E'.
  RETURN.
ENDIF.

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING i_structure_name = 'VBAK'
  TABLES t_outtab = orders.
```

## BAPI Call Pattern

```abap
" 1. Populate header/items
" 2. Call BAPI
" 3. Check return for errors
" 4. Commit or rollback
CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
  EXPORTING goodsmvt_header = ls_header goodsmvt_code = '01'
  IMPORTING materialdocument = lv_matdoc
  TABLES goodsmvt_item = lt_items return = ls_return.

IF lv_matdoc IS NOT INITIAL.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.
```

## Data Migration Pattern

```abap
CALL FUNCTION 'GUI_UPLOAD'
  EXPORTING filename = p_file has_field_separator = 'X'
  TABLES data_tab = lt_file
  EXCEPTIONS file_open_error = 1 OTHERS = 2.
IF sy-subrc <> 0.
  MESSAGE 'File upload failed' TYPE 'E'.
  RETURN.
ENDIF.

LOOP AT lt_file INTO DATA(row).
  " populate BAPI structures from row
  " call BAPI
  " check return, commit/rollback per record
ENDLOOP.
```

## abaplint Config

```json
{
  "global": { "files": "./**/*.{abap,prog.abap}" },
  "syntax": { "version": "v757", "errorNamespace": "." },
  "rules": {
    "begin_end_names": true,
    "check_ddic": false,
    "unknown_types": false,
    "begin_single_include": false
  }
}
```

## Common BAPIs

| BAPI                           | Purpose                                   |
| ------------------------------ | ----------------------------------------- |
| BAPI_GOODSMVT_CREATE           | Post goods movements (101, 201, 301, 561) |
| BAPI_MATERIAL_SAVEDATA         | Create/change material master             |
| BAPI_SALESORDER_CREATEFROMDAT2 | Create sales orders                       |
| BAPI_PO_CREATE1                | Create purchase orders                    |
| BAPI_ACC_DOCUMENT_POST         | Post accounting documents                 |
| BAPI_TRANSACTION_COMMIT        | Commit with wait = 'X'                    |
| BAPI_TRANSACTION_ROLLBACK      | Rollback on failure                       |
