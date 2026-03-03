require "digest"
require "json"
require "fileutils"

module Hubspot
  module Export
    class FileStore
      attr_reader :run

      def initialize(run)
        @run = run
      end

      def run_dir
        Rails.root.join("exports", "run_id=#{run.run_id}")
      end

      def ensure_layout!
        %w[manifests raw_jsonl crm metadata].each do |subdir|
          FileUtils.mkdir_p(run_dir.join(subdir))
        end
      end

      def absolute_path(relative_path)
        run_dir.join(relative_path)
      end

      def append_jsonl(relative_path, rows)
        return if rows.empty?

        path = absolute_path(relative_path)
        FileUtils.mkdir_p(path.dirname)

        File.open(path, "a") do |file|
          rows.each { |row| file.puts(JSON.generate(row)) }
        end
      end

      def write_json(relative_path, payload)
        path = absolute_path(relative_path)
        FileUtils.mkdir_p(path.dirname)
        File.write(path, JSON.pretty_generate(payload))
      end

      def write_text(relative_path, payload)
        path = absolute_path(relative_path)
        FileUtils.mkdir_p(path.dirname)
        File.write(path, payload)
      end

      def line_count(relative_path)
        path = absolute_path(relative_path)
        return 0 unless File.exist?(path)

        count = 0
        File.foreach(path) { count += 1 }
        count
      end

      def checksum(relative_path)
        path = absolute_path(relative_path)
        return nil unless File.exist?(path)

        Digest::SHA256.file(path).hexdigest
      end
    end
  end
end
