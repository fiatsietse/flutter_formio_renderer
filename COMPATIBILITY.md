# Form.io Compatibility Matrix & Behavioral Specification

This document defines the compatibility target, supported components, property mappings, logic semantics, and multi-step wizard behaviors of `flutter_formio_renderer`.

## 1. Pinned Reference Target

| Property | Value |
|---|---|
| **Reference Renderer** | `formiojs` (Official Form.io JavaScript Renderer) |
| **Pinned Target Version** | `4.19.0` (compatible with 4.14.x through 4.19.x specifications) |
| **Schema Standard** | Form.io Form JSON Schema Specification v4 |
| **Default Target Platforms** | Android, iOS, Web, macOS, Windows, Linux |

---

## 2. Component Compatibility Matrix

Status legend:
- **Supported**: Full native Flutter widget rendering, validation, conditional logic, and submission serialization.
- **Partially Supported**: Core rendering and input supported; specialized browser-only DOM configurations documented below.
- **Unsupported**: Not implemented in native Flutter; triggers a visible development placeholder (`FormioUnsupportedWidget`) and structured diagnostic. In `strictMode: true`, blocks submission if required.

### 2.1 Basic Inputs

| Component | Status | Form.io Properties Honored | Notes |
|---|---|---|---|
| `textfield` | **Supported** | `label`, `placeholder`, `description`, `tooltip`, `prefix`, `suffix`, `defaultValue`, `multiple`, `disabled`, `hidden`, `validate` | Supports `multiple: true` with dynamic item addition/removal. |
| `textarea` | **Supported** | `rows`, `placeholder`, `description`, `tooltip`, `defaultValue`, `disabled`, `hidden`, `validate` | Pure native multi-line text field. |
| `number` | **Supported** | `min`, `max`, `step`, `placeholder`, `defaultValue`, `disabled`, `hidden`, `validate` | Numeric keyboard, parses integer/decimal values. |
| `password` | **Supported** | `protected`, `placeholder`, `minLength`, `maxLength`, `disabled`, `hidden` | Obscured text with native show/hide eye toggle. |
| `email` | **Supported** | `placeholder`, `defaultValue`, `disabled`, `hidden`, `validate.required` | RFC 5322 compatible format validation. |
| `url` | **Supported** | `placeholder`, `defaultValue`, `disabled`, `hidden`, `validate.required` | Standard URI scheme (HTTP/HTTPS) validation. |
| `phoneNumber` | **Supported** | `placeholder`, `defaultValue`, `disabled`, `hidden` | Phone keypad input and format verification. |
| `checkbox` | **Supported** | `label`, `defaultValue`, `disabled`, `hidden`, `validate.required` | Boolean storage; required means must be checked (`true`). |
| `selectboxes` | **Supported** | `values`, `defaultValue`, `minSelectedCount`, `maxSelectedCount` | Stored as map of boolean flags: `{"optA": true, "optB": false}`. |
| `radio` | **Supported** | `values`, `defaultValue`, `disabled`, `hidden`, `validate.required` | Single selection stored as primitive value. |
| `select` | **Supported** | `dataSrc` ('values', 'url'), `data`, `multiple`, `valueProperty`, `template`, `searchField` | Local and remote sources via `FormioRemoteOptionsAdapter`. |
| `datetime` | **Supported** | `enableDate`, `enableTime`, `format`, `defaultValue`, `disabled` | Material Date & Time pickers; ISO 8601 storage. |
| `day` | **Supported** | `dayFirst`, `fields`, `defaultValue`, `disabled` | Tri-input (Day/Month/Year) stored as `DD/MM/YYYY`. |
| `time` | **Supported** | `format`, `defaultValue`, `disabled` | Time picker stored as `HH:mm:ss`. |
| `hidden` | **Supported** | `defaultValue`, `key` | Stored in submission data without rendering any UI. |
| `button` | **Supported** | `action` ('submit', 'reset', 'next', 'previous', 'custom', 'event'), `theme` | Triggers form submission, reset, or wizard navigation. |

### 2.2 Layout & Presentation

| Component | Status | Form.io Properties Honored | Notes |
|---|---|---|---|
| `panel` | **Supported** | `title`, `collapsible`, `collapsed`, `theme`, nested `components` | Card container; does **not** create data nesting (standard Form.io semantics). |
| `fieldset` | **Supported** | `legend`, nested `components` | Bordered group box with legend. |
| `columns` | **Supported** | `columns` array (`width`, `offset`), nested `components` | Responsive grid: horizontal row on tablet/desktop, stacks on mobile. |
| `table` | **Supported** | `rows` matrix of cells, nested `components` | Multi-column and multi-row table layout. |
| `tabs` | **Supported** | `components` array with tab labels | Native Flutter `TabBar` and `TabBarView`. |
| `content` | **Supported** | `html` | Pure native rich text rendering of headings, paragraphs, bold, italic, lists, and code. |
| `htmlelement` | **Supported** | `tag`, `content`, `attrs`, `className` | Safe native HTML tag renderer without webview overhead. |
| `well` | **Supported** | nested `components` | Aliased to panel container per Form.io conventions. |

### 2.3 Structured Data & Repeating Groups

| Component | Status | Form.io Properties Honored | Notes |
|---|---|---|---|
| `container` | **Supported** | `key`, nested `components`, `defaultValue` | Creates a nested map in submission data: `data[key] = { ... }`. |
| `datagrid` | **Supported** | `key`, `components`, `minRows`, `maxRows`, `addAnother`, `defaultValue` | Repeating array of objects: `data[key] = [ { ... } ]`. Row-scoped reactive logic. |
| `editgrid` | **Supported** | `key`, `components`, `minRows`, `maxRows`, `addAnother`, inline editing | Collapsible summary view with draft row editing, save and cancel. |

### 2.4 Advanced Integrations

| Component | Status | Form.io Properties Honored | Notes |
|---|---|---|---|
| `file` | **Supported** | `storage`, `url`, `multiple`, `filePattern` | Pluggable `FormioFileStorageAdapter`. Upload progress, delete, metadata serialization. |
| `signature` | **Supported** | `height`, `penColor`, `backgroundColor`, `validate.required` | Vector signature pad with smooth curves and base64 PNG data URL export. |
| `nestedform` / `form` | **Supported** | `src`, `form` (ID), nested `components` | Embedded subforms via pluggable `FormioSubformResolver`. |
| `survey` | **Partially Supported** | `questions`, `values` | Renders as matrix of radio options. |
| `tree` | **Unsupported** | Hierarchical node editing | Emits diagnostic and placeholder. |
| `pdf` / `reCaptcha` | **Unsupported** | Browser-specific DOM features | Requires platform-specific webview integration. |

---

## 3. Reactive Logic & Conditions Matrix

| Feature | Status | Details |
|---|---|---|
| **Simple Conditional** | **Supported** | `conditional: { show: true|false, when: "fieldKey", eq: "val" }`. Supports string and boolean loose equality. |
| **JSON Logic Conditional** | **Supported** | `conditional: { json: { "==": [ { "var": "data.field" }, "val" ] } }`. Pure Dart JSON Logic engine. |
| **Calculated Values** | **Supported** | Evaluates JSON Logic calculations. Supports row-level scope (`row.field`) and form-level scope (`data.field`). |
| **Logic Rules** | **Supported** | Triggers: `simple`, `json`, `javascript`. Actions: `property` (`required`, `disabled`, `hidden`, `label`), `value`. |
| **Dependency Graph** | **Supported** | Extracts dependencies across fields, computes topological evaluation order. |
| **Cycle Detection** | **Supported** | Tarjan/DFS cycle detection. Prevents infinite recursion by enforcing `maxLogicIterations` (default 10) and emitting `FormioDiagnostic`. |
| **clearOnHide** | **Supported** | When a component becomes hidden, value is cleared if `clearOnHide: true` (default), or retained if `false`. |

---

## 4. Multi-Step Wizard Matrix

| Wizard Behavior | Status | Description |
|---|---|---|
| **Page Derivation** | **Supported** | In `display: "wizard"`, top-level `panel` components are derived as wizard pages. |
| **Step Indicators** | **Supported** | Numbered and titled horizontal breadcrumb indicators with active/completed states. |
| **Step Validation** | **Supported** | Advancing with `Next` validates only visible fields on the current page. |
| **Backward Navigation** | **Supported** | `Previous` navigation is never blocked by incomplete or invalid fields on current step. |
| **Conditional Page Skipping** | **Supported** | If a page is conditionally hidden based on previous answers, wizard automatically skips it. |
| **Data Retention Across Steps** | **Supported** | All entered values survive navigation forward and backward. |
| **Final Submission Validation** | **Supported** | Submitting on the final page triggers full validation across all visible steps. |

---

## 5. Platform Differences & Execution Environments

| Platform | Native Widget Engine | File Storage | Script Execution |
|---|---|---|---|
| **Android** | Pure Flutter Canvas / Material 3 | Memory, HTTP, or custom adapter | Sandboxed Dart JSON Logic (Default); QuickJS / WebView optional |
| **iOS** | Pure Flutter Canvas / Material 3 | Memory, HTTP, or custom adapter | Sandboxed Dart JSON Logic (Default); JavaScriptCore optional |
| **Web** | Pure Flutter Canvas / CanvasKit / Skwasm | Browser blob / upload endpoint | Sandboxed Dart JSON Logic (Default); Web Worker optional |
| **macOS / Windows / Linux** | Pure Flutter Canvas / Material 3 | File system / HTTP adapter | Sandboxed Dart JSON Logic (Default) |

### Preservation of Unrecognized Schema Properties
To ensure backward compatibility with future Form.io versions and enterprise plugins, all unrecognized properties in form schemas and component definitions are preserved in `component.rawJson` and accessible via `component.properties`.
