class BitbucketMilestoneResource < BitbucketResource
  def find_by_id(id)
    prepare_request
    response = http_get bitbucket_milestones_path
    process_response(response, 200) do |milestones|
      return milestones.find { |milestone| milestone['id'] == id }
    end
  end

  def find_by_name(name)
    prepare_request
    response = http_get bitbucket_milestones_path
    process_response(response, 200) do |milestones|
      return milestones.find { |milestone| milestone['name'] == name }
    end
  end

  def create(new_milestone)
    prepare_request
    response = http_post bitbucket_milestones_path, new_milestone.to_query, {
      'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
    }
    process_response(response, 200) do |milestone|
      return milestone
    end
  end

  def update(id, updated_milestone)
    prepare_request
    response = http_put "#{bitbucket_milestones_path}/#{id}", updated_milestone.to_query, {
      'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
    }
    process_response(response, 200) do |milestone|
      return milestone
    end
  end

private

  def bitbucket_milestones_path
    "#{API_URL}/repositories/#{@service.data.repository}/issues/milestones"
  end
end
