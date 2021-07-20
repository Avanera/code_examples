# == Schema Information
#
# Table name: eo_inboxes
#  id                                    :bigint(8)        not null, primary key
#  from_name                             :string
#  email                                 :string
#  receive_host                          :string
#  receive_port                          :string
#  receive_username                      :string
#  receive_password                      :string
#  cursor_position                       :string
#
#
# task:
# implement a service to find mails in required mailboxes
#
# gem 'mail' is used internally
#
class ImapMailsFinder
  def initialize(eo_inbox)
    @eo_inbox = eo_inbox
    @found_mails = []
  end

  def call
    mailboxes = find_mailboxes
    mailboxes.each do |mailbox|
      begin
        mails = find_mails_in(mailbox)
        mails&.each { |mail| @found_mails.push(mail) }
      rescue StandardError => e
        Rails.logger.error(
          "Failed to fetch mails from #{mailbox} of '#{@eo_inbox.email}' EoInbox. "\
          "Original error was: #{e}."
        )
        next
      end
    end

    @found_mails.uniq(&:message_id)
  end

  private

  def find_mailboxes
    # select required mailboxes using public method Mail::IMAP#connection(&block) of gem 'mail'
    retriever.connection do |imap|
      imap.list('', '*').map(&:name).reject { |m| mailbox_to_reject?(m) }
    end
  end

  def find_mails_in(mailbox)
    cursor_position = build_cursor_position
    retriever.find(
      mailbox: mailbox,
      what: :last,
      count: 20,
      order: :asc,
      read_only: true,
      keys: ['SINCE', cursor_position, 'TO', @eo_inbox.email]
    )
  end

  def build_cursor_position
    if @eo_inbox.cursor_position
      return DateTime.strptime(@eo_inbox.cursor_position.to_s, '%s').strftime('%d-%b-%Y')
    end

    (Time.now.utc - 1.week).strftime('%d-%b-%Y')
  end

  def mailbox_to_reject?(mailbox)
    # eg. exclude drafts folders
    mailbox.include?('Drafts')
  end

  def retriever
    @retriever ||= Mail::IMAP.new(
      address: @eo_inbox.receive_host,
      port: @eo_inbox.receive_port,
      user_name: @eo_inbox.receive_username,
      password: eo_inbox_encryptor.decrypt(@eo_inbox.receive_password),
      enable_ssl: true
    )
  end

  def eo_inbox_encryptor
    # eo_inbox_encryptor stub
  end
end
