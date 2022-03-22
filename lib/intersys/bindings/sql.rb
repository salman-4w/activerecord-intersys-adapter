module Intersys
  # Class representing one query
  # You shouldn't create it yourself
  class Query
    attr_reader :database

    def rows
      return @rows if defined? @rows

      @rows = []

      self.each { |row| @rows << row }

      @rows
    end

    def fill(data)
      self.each {|row| data << row}
      self
    end

    def columns
      (1..self.column_count).map { |index| self.column_name index }
    end
  end

  # Class representing Cache database connection
  class Database

    def self.connection_lost!
      @@connection_lost = true
    end

    def self.connection_restored!
      @@connection_lost = false
    end

    def self.connection_lost?
      @@connection_lost ||= false
    end

    protected
    def strip_param(query, name)
      if match_data = query.match(/#{name}(\s*)(\d+)/i)
        query[match_data.to_s] = ""
        match_data.captures.last
      end
    end

    public

    def prepare(sql)
      @limit = strip_param(sql, "LIMIT")
      @offset = strip_param(sql, "OFFSET")
      q = Query.new(self, sql)
      q.limit = @limit if @limit
      q.offset = @offset if @offset
      q
    end

    def active?
      return false if connection_lost?

      now = Time.now.to_i
      (now - @@last_query_at) < connection_timeout
    end

    # TODO: /csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_variables
    # Somehow, I should extract from Cache %ROWCOUNT and %ROWID
    def affected_rows
      query("select %ROWCOUNT")
    end

    def insert_id
      0
    end

    # private
    # return connection timeout setting in seconds
    def connection_timeout
      @connection_timeout ||= (@options[:connection_timeout] || 60) * 60
    end
  end
end
