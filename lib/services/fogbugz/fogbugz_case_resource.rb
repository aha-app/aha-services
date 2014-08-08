class FogbugzCaseResource < FogbugzResource

  def search(case_number)
    command(:search, {q: "case:#{ case_number }"}).try(:cases).try(:case)
  end

  def new_case(parameters, attachments)
    command(:new, parameters, attachments).case
  end

  def edit_case(parameters, attachments)
    command(:edit, parameters, attachments).case
  end
end