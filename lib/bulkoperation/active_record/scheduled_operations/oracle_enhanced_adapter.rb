module ActiveRecord
  module Bulkoperation
    module OracleEnhancedAdapter
  
      def find_foreign_master_tables_sql_array(table_name)
        sql = "select
                 m.table_name
               from
                 user_constraints m join user_constraints d on (m.constraint_name = d.r_constraint_name)
               where
                 d.table_name = ?"
        [sql, table_name.upcase]
      end

      def find_foreign_detail_tables_sql_array(table_name)
        sql = "select
                 d.table_name
               from
                 user_constraints m join user_constraints d on (m.constraint_name = d.r_constraint_name)
               where
             m.table_name = ?"
        [sql, table_name.upcase]
      end

      def find_detail_references_sql_array(table_name)
        sql = "select
          m.table_name master_table,
          ( select listagg( column_name, ',' ) within group (order by position) from user_cons_columns where constraint_name = m.constraint_name ) master_columns,
          d.table_name detail_table,
          ( select listagg( column_name, ',' ) within group (order by position) from user_cons_columns where constraint_name = d.constraint_name ) detail_columns
          from
          user_constraints m join user_constraints d on( m.constraint_name = d.r_constraint_name )
          where m.table_name = ?"
        [sql, table_name.upcase]
      end

    end
  end
end