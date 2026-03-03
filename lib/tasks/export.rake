namespace :export do
  desc "Run a full HubSpot dump: rake export:full_dump[portal_id]"
  task :full_dump, [:portal_id] => :environment do |_task, args|
    run = Hubspot::Export::Runner.full_dump(portal_id: args[:portal_id])
    puts "full dump succeeded run_id=#{run.run_id} tables=#{run.export_tables.count} records=#{run.total_records}"
  end

  desc "Run an incremental HubSpot dump: rake export:incremental[portal_id]"
  task :incremental, [:portal_id] => :environment do |_task, args|
    run = Hubspot::Export::Runner.incremental(portal_id: args[:portal_id])
    puts "incremental dump succeeded run_id=#{run.run_id} tables=#{run.export_tables.count} records=#{run.total_records}"
  end

  desc "Resume a failed/incomplete run: rake export:resume[run_id]"
  task :resume, [:run_id] => :environment do |_task, args|
    raise ArgumentError, "run_id is required" if args[:run_id].blank?

    run = Hubspot::Export::Runner.resume(run_id: args[:run_id])
    puts "resume succeeded run_id=#{run.run_id} status=#{run.status}"
  end

  desc "Verify manifest and table counts: rake export:verify[run_id]"
  task :verify, [:run_id] => :environment do |_task, args|
    raise ArgumentError, "run_id is required" if args[:run_id].blank?

    run = ExportRun.find_by!(run_id: args[:run_id])
    store = Hubspot::Export::FileStore.new(run)
    result = Hubspot::Export::Verifier.new(run: run, store: store).verify!

    puts JSON.pretty_generate(result)
    raise "verification failed: #{result[:mismatch_count]} mismatches" if result[:mismatch_count].positive?
  end

  desc "Print reconciliation report for run: rake export:reconcile[run_id]"
  task :reconcile, [:run_id] => :environment do |_task, args|
    raise ArgumentError, "run_id is required" if args[:run_id].blank?

    run = ExportRun.find_by!(run_id: args[:run_id])
    store = Hubspot::Export::FileStore.new(run)
    report = Hubspot::Export::ReconciliationReport.new(run: run, store: store).as_json

    puts JSON.pretty_generate(report)
    raise "reconciliation has mismatches" if report[:mismatch_count].positive?
  end

  desc "Generate/print coverage matrix for run: rake export:coverage[run_id]"
  task :coverage, [:run_id] => :environment do |_task, args|
    raise ArgumentError, "run_id is required" if args[:run_id].blank?

    run = ExportRun.find_by!(run_id: args[:run_id])
    generator = Hubspot::Export::CoverageMatrixGenerator.new(run: run)
    puts generator.as_markdown
  end
end
