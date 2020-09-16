class ChangeCharacterSetToUtf8Mb4 < ActiveRecord::Migration[6.0]
  CHARSET = 'utf8mb4'
  COLLATION = 'utf8mb4_unicode_ci'

  def db
    ActiveRecord::Base.connection
  end

  def up
    execute "ALTER DATABASE `#{db.current_database}` CHARACTER SET #{CHARSET} COLLATE #{COLLATION};"
    db.tables.each do |table|
      execute "ALTER TABLE `#{table}` CONVERT TO CHARACTER SET #{CHARSET} COLLATE #{COLLATION};"

      db.columns(table).each do |column|
        case column.sql_type
          when /([a-z]*)text/i
            default = (column.default.blank?) ? '' : "DEFAULT '#{column.default}'"
            null = (column.null) ? '' : 'NOT NULL'
            execute "ALTER TABLE `#{table}` MODIFY `#{column.name}` #{column.sql_type.upcase} CHARACTER SET #{CHARSET} COLLATE #{COLLATION} #{default} #{null};"
          when /varchar\(([0-9]+)\)/i
            sql_type = column.sql_type.upcase
            default = (column.default.blank?) ? '' : "DEFAULT '#{column.default}'"
            null = (column.null) ? '' : 'NOT NULL'
            execute "ALTER TABLE `#{table}` MODIFY `#{column.name}` #{sql_type} CHARACTER SET #{CHARSET} COLLATE #{COLLATION} #{default} #{null};"
        end
      end
    end
  end
end
