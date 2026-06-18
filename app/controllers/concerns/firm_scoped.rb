module FirmScoped
  private

  def scope_clients
    return Client.all if current_accountant.superuser?
    return Client.where(firm_id: current_accountant.firm_id) if current_accountant.admin?

    Client.where(id: communicated_client_ids)
  end

  def scope_threads
    return EmailThread.all if current_accountant.superuser?
    return EmailThread.joins(:client).where(clients: { firm_id: current_accountant.firm_id }) if current_accountant.admin?

    EmailThread.where(client_id: communicated_client_ids)
  end

  def communicated_client_ids
    Client.joins(email_threads: :email_messages)
          .where(email_messages: { accountant_id: current_accountant.id })
          .select(:id)
  end
end
