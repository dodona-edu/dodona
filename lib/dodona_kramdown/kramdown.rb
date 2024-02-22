module DodonaKramdown
  module Converter
    # Converts a Kramdown::Document to HTML.
    module DodonaHtml
      # Codeblock is customized in order to implement a different output to Mermaid
      #
      # Mermaid requires `<div class="mermaid"></div>` surrounding the content in order
      # to trigger the unobtrusive JS.
      def convert_codeblock(element, opts)
        if element.options[:lang] == 'mermaid'
          %(<div class="mermaid">#{element.value}</div>\n)
        else
          super
        end
      end
    end
  end
end

Kramdown::Converter::Html.prepend(DodonaKramdown::Converter::DodonaHtml)
