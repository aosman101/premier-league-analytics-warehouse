{#-
Override dbt's default schema naming to use the custom schema as-is
instead of prefixing it with the target schema (which caused datasets
like football_analytics_football_analytics). On BigQuery, the schema
maps to the dataset name.
-#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none or custom_schema_name == '' -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
