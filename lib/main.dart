
      // Serial number restarts each scan date; registration is counted per court.
      var dailyCount = 0;
      for (var r = 1; r < sheet.maxRows; r++) {
        final rawValue = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIndex('C'), rowIndex: r),
        ).value;

        String existingDate = '';
        if (rawValue is DateTime) {
          existingDate = fmtDate(rawValue);
        } else if (rawValue != null) {
          existingDate = rawValue.toString().trim();
        }

        final parsedExisting = DateTime.tryParse(existingDate);
        if (parsedExisting != null) {
          existingDate = fmtDate(parsedExisting);
        }

        if (existingDate == scanDate) dailyCount++;
      }
