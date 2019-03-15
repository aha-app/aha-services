module AhaServices
  module Services
    module Common
      module ColorConverter
        AHA_COLOR_TABLE = {
          # aha => jira
          "#D50000" => "#d04437", # red
          "#000000" => "#333333", # black
          "#999999" => "#707070", # gray
          # "" => "#cccccc", # lightgray
          # "" => "#205081", # darkblue
          "#0073CF" => "#59afe1", # light blue
          # "" => "#14892c", # green
          "#64B80B" => "#8eb021", # light green
          "#F9931A" => "#f79232", # orange
          # "" => "#f6c342", # yellow
          # "" => "#654982", # purple
          # "" => "#f691b2", # pink
        }
        JIRA_COLOR_TABLE = AHA_COLOR_TABLE.clone.invert
        AHA_COLOR_TABLE.freeze
        JIRA_COLOR_TABLE.freeze

        def self.aha_color_to_jira(color)
          AHA_COLOR_TABLE[color&.upcase] || color
        end

        def self.jira_color_to_aha(color)
          JIRA_COLOR_TABLE[color&.downcase] || color
        end
      end
    end
  end
end
