class SiteFetcher
  @queue = :fetch

  # Fetch a site and log the result and update site according to the result.
  #
  # Side Effect: If the status changed from anything to FAILED, or changed 
  # from FAILED to OK, send an email notification.
  #
  # site_id - id for the site to be fetched
  def self.perform(site_id, mailer=SitesMailer)
    site       = Site.find(site_id)
    was_failed = site.failed?
    SiteWatcher.new(site).watch

    if was_failed && site.ok?
      mailer.notify_resolved(site.id).deliver
    elsif !was_failed && site.failed?
      mailer.notify_error(site.id).deliver
    end

    site.save!
  end
  
  def self.get_url(url)
    request = Typhoeus::Request.new(url, :method => :get, :timeout => 10000, :follow_location => true)
    hydra = Typhoeus::Hydra.hydra
    hydra.queue(request)
    hydra.run
    request.response    
  end
end