class XmlResp
  def build(hs={})
    dfs(xml:hs)
  end

  private
  def dfs(val)
    case val
      when Hash
        sub_lines = val.map{|k,v|"<#{k}>#{dfs(v)}</#{k}>"}
        sub_lines = sub_lines.join("\n")
        "\n#{sub_lines}\n"
      when String
        "<![CDATA[#{val}]]>"
      else
        val.to_s
    end
  end
end