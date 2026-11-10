<!-- gf-brief source=dd6f446f8df3507741c6c53dbe2443bc6ff73dbf98482d88e256fa5b68493307 written=2026-11-10T19:27:19+03:00 -->
# PinlabelLoupe

## What it is

PinlabelLoupe is a food-label reference and comparison app for people who want to inspect ingredients, allergens and nutrients. Users can find products in a catalog, scan a product code or enter a label by hand, then save labels and record choices.

## Launch and onboarding

A cold launch opens the “Desk” tab directly. There is no onboarding sequence.

1. The screen shows “PinlabelLoupe  /  label bureau”, “01—03”, “01   /   FIELDWORK” and “The lab”.
2. The main panel says “FIELD STUDY     ·     LL—01”, “Under the lens” and “Read the ingredients, check allergens and compare nutrients per 100 g.” Tapping “Find a label” opens “Food catalog”.
3. The “Saved” and “Choices” counters open the corresponding sections of “Archive”.
4. Under “On the desk” and “recent dossiers”, a fresh installation shows “A fresh desk” and “Look up a name or scan a barcode. The labels you open will stay here.”
5. The bottom tabs are “Desk”, “Compare” and “Archive”.

## Screens

### “Desk”

“Find a label” opens “Food catalog”. “Saved” opens “Archive” at “Collection”; “Choices” opens it at “Choice history”. Recently opened product rows lead to their “Dossier”; up to six are shown.

### “Food catalog”

The “Name, brand or barcode” field filters products available on the device. “Clear search” clears the field. “Search Open Food Facts” searches the online catalog, and “Scan a barcode” opens “Barcode scanner”. Tapping a product opens its dossier, or fills the selected comparison position when the catalog was opened from “Compare”. “Close” dismisses the catalog.

Results appear under “On this device” or “Search results”. During a search the screen says “Searching the catalog…”. If there are no local matches, it says “No matches on this device. Search Open Food Facts or enter the details from the label.”

“Enter label by hand” opens “New product”. The screen also says “Product data comes from Open Food Facts contributors. Check the package for the current ingredients.” The “Open Food Facts · Data ODbL · Photos CC BY-SA” link opens the source’s terms.

### “Barcode scanner”

The camera view says “Point the camera at the product barcode”. A recognized eligible code closes the scanner and searches the catalog. “Close” returns to the catalog.

If scanning is unavailable, “Scanner unavailable” appears with an explanation. “Back to search” returns to the catalog; “Open Settings” appears when camera access was denied and opens the app’s system settings.

### “New product”

The “Product” section has “Product name” and “Brand” fields. “Per 100 g” has “Energy, kcal”, “Protein, g”, “Carbohydrates, g” and “Fat, g”; its guidance says “Leave a field empty if the value is missing from the label.” The “Ingredients” section has “Ingredient list from the package”.

“Use this product” creates the entry and opens its dossier, or places it in the selected comparison position. The navigation back control returns to “Food catalog”.

### “Dossier”

A dossier displays the product name, optional brand and image, and either “Dossier  /  manual entry” or “Dossier  /  ” followed by its catalog code.

“Log a choice” adds an entry to history and displays “Choice added to your history”. “Save label” adds the product to the collection; once saved, the control reads “Saved” and removes it when tapped. “Compare” adds it to an available position and opens “Compare”. If both positions are occupied, “Which label should this replace?” offers the existing product names as replacement choices.

“01  /  Ingredients”, “02  /  Allergens” and “03  /  Per 100 g” show available label information. Nutrient rows are “Energy”, “Protein”, “Fat”, “Carbs”, “Sugars”, “Fiber” and “Salt”. The screen explains “A dash indicates an unlisted value.”

Catalog products have “View on Open Food Facts”, which opens the product’s source page. Hand-entered products show “Manually entered label”.

### “Compare”

“02   /   SIDE BY SIDE” and “Compare” introduce the screen: “Put two labels side by side. Every value is shown per 100 g.”

Each of the “A” and “B” positions has “Choose a label” when empty. A filled position shows the product name and “Replace”, which opens the catalog; its remove control is accessible as “Remove” followed by the product name. With two products, the table shows “Nutrient”, “A”, “B” and “B − A” for the seven dossier nutrients. It explains “B − A is the difference per 100 g. A dash indicates missing label data.”

### “Archive”

“03   /   PERSONAL INDEX” and “Archive” appear above the “Collection” and “Choice history” selector.

In “Collection”, “Filter by name or brand” filters saved products and “Clear filter” clears the text. Tapping a product opens its dossier.

In “Choice history”, “Entries  /  ” is followed by the number of choices. Each entry shows a product and time; tapping it opens the dossier. “Delete choice” opens “Delete this choice from your history?”, where “Delete choice” confirms removal.

### Apple Watch

The companion opens “PinlabelLoupe” with “LABEL BUREAU”, “Collection”, and saved and choice counts. A saved product opens a detail showing its name, brand when available, “PER 100 G”, “Sugars”, “Salt” and “Choices”. “Log a choice” records or queues a choice for the iPhone. A “History” alert reports the outcome, with “Done” to dismiss it.

When the collection is empty, the watch says “Save a label to your collection on iPhone. It will appear here after syncing.” “Refresh from iPhone” requests an update.

### Widget

The small and medium “PinlabelLoupe archive” widget is described as “Your latest choice and collection size.” It shows “LABELLOUPE”, the latest choice and counts, or “Field archive” and “Log a choice from an open label.” when there is no choice. Tapping it opens the latest dossier or the archive.

## Features

- Find a label by name, brand or barcode in “Food catalog”.
- “Scan a barcode” or “Enter label by hand”.
- Read “Ingredients”, “Allergens” and nutrients “Per 100 g”.
- “Save label” to “Collection” and filter saved labels.
- “Compare” two labels and see “B − A”.
- “Log a choice” and manage “Choice history”.
- Reopen “recent dossiers”.
- View saved labels and log choices on Apple Watch.
- See the latest choice and counts in the “PinlabelLoupe archive” widget.

## Behaviours that can look like bugs

- “Search Open Food Facts” is disabled until the search has at least two characters, and while a search is underway. Enter a longer query or wait for the current search.
- “Use this product” is disabled until “Product name” is filled and entered numbers are valid. Energy must be from 0 to 1,000 kcal; the other numeric fields must be from 0 to 100 g. Missing values may be left empty.
- Before two products are selected, “Compare” shows “Pick a pair” and “Choose two products above, or add one from an open dossier.” Fill both positions to see the table.
- A product cannot occupy both comparison positions. Choosing the same label shows “This label is already on the comparison table.” Select a different label or remove the existing one. When both positions are full, adding from a dossier asks “Which label should this replace?”
- An unsaved collection shows “An empty shelf” and “Save a label from its dossier to keep it here and on your watch.” A filter with no results shows “No matches” and “Try a different part of the name.”
- An unused history shows “Your history is empty” and “Tap Log a choice on a product you pick. Its name and the time will appear here.” Each tap on “Log a choice” adds another entry; entries can be deleted individually.
- Missing ingredients show “Ingredients are unlisted. Check the package.” Missing allergen information shows “No allergen data” and “Check the ingredient list and allergen warnings on the package.” Missing nutrient values appear as “—”.
- A search can report “No matches in Open Food Facts.”, “This barcode isn’t in the catalog yet.”, “The catalog is limiting requests. Try again in a minute.”, “Couldn’t load the product data. Try again.” or “Couldn’t reach the catalog. Use a saved product or enter the label by hand.” Try another search, retry later or enter the label manually.
- Scanner failures can say “On this device, enter the digits printed under the barcode in the search field.”, “Camera access is unavailable. You can type the barcode in the search field.”, “The camera is busy. Try again later or enter the barcode by hand.” or “Enter the digits printed under the barcode in the search field.” Use “Back to search”, type the digits or, when offered, use “Open Settings”.
- If a change cannot be saved, the “PinlabelLoupe” alert says “This device could not save your changes.” and offers “Close”.
- The watch may say “Your watch is still connecting. Try again in a moment.”, “Your iPhone could not save this choice. Try again.” or “Choice queued. It will appear in history when your iPhone reconnects.” Reconnect or retry as indicated.

## Starter content and resume

The catalog includes 15 starter food products, including “Quaker Oats”, “Nutella” and “Penne Rigate N°73”. The desk, collection, comparison and choice history start empty in a normal installation.

Saved labels, recent dossiers, comparison positions, manually entered products and choice history persist for later use. An unfinished manual-entry form is not saved for resumption.

## Permissions

Camera access is requested when the user opens “Scan a barcode” on a supported device. The usage description is: “Scan a barcode with the camera to find its label in Open Food Facts.”

## Absent

There is no login or account, in-app purchase, advertising, analytics, account deletion flow or App Tracking Transparency prompt. Users can create their own product entries and choice history.

## Data and support

The personal collection, entered products, comparison and history are stored on the device and shared with the paired Apple Watch and widget. Catalog searches and product images use the internet; search terms or barcode digits are sent to Open Food Facts. There is no on-screen Contact or Support control.

## Scanning and health

The scanner recognizes product barcodes and QR codes, but accepts only a numeric product code for catalog lookup; a general QR link or other nonnumeric content will not advance the search. Barcode digits can also be typed.

The app displays product ingredients, allergens and nutrition per 100 g. It does not provide medical advice or health ratings. The catalog identifies Open Food Facts contributors as the source and links to its terms; each catalog dossier links to its product page. Manually entered information comes from the user.

## Platform

The interface is in English, with no region selector or region-specific flow. The app supports iPhone and iPad on iOS 17.0 or later. iPhone supports portrait and both landscape orientations; iPad also supports upside-down portrait. The companion requires watchOS 10.0 or later.

## Category

Food & Drink.
