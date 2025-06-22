Product Requirement: FocusPulse iOS App - Share/Export Screen

Purpose: To enable users to easily export their productivity data and share their achievements while maintaining privacy controls and offering multiple format options.

UI Components:

- Navigation Bar: Standard iOS navigation with "Export Data" title and cancel/close button
- Export Options Section: Grouped list of data format choices (JSON, CSV, PDF Report) with descriptions
- Date Range Selector: Date picker controls to specify export period (last week, month, all time, custom range)
- Data Privacy Section: Checkboxes for what data to include (sessions, settings, personal stats) with privacy explanations
- Preview Area: Sample of export data or formatted report preview before sharing
- Share Destination Buttons: Native iOS share sheet integration with common destinations (Files, Email, AirDrop)
- Progress Indicator: Loading state while preparing export data
- Success/Error States: Confirmation messages and error handling with retry options

Visual Style:

- Theme: Standard iOS modal presentation with light/dark mode support
- Primary color: System Blue #007AFF for share buttons and primary actions
- Secondary color: System Gray #8E8E93 for secondary text and option descriptions
- Success color: System Green #34C759 for successful export confirmations
- Warning color: System Orange #FF9500 for privacy notices and warnings
- Error color: System Red #FF3B30 for error states and failed exports
- Spacing: Standard iOS modal spacing with 20px margins, 16px between sections, 8px for related items
- Borders: iOS standard grouped section styling with 10px corner radius
- Typography: SF Pro Text 17pt for main options, 15pt for descriptions, 13pt for privacy text, 20pt for headings
- Icons/images: SF Symbols for export types (doc.text, tablecells, doc.richtext), share icon (square.and.arrow.up) 