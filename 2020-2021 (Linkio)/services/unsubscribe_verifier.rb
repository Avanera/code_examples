# task:
# implement a servise class to encode and decode sensitive data
#
# Expected param for UnsubscribeVerifier.verify(param):
#  {
#    encoded_marketer_id: UnsubscribeVerifier.generate(marketer.id),
#    encoded_user_id: UnsubscribeVerifier.generate(user.id)
#  }
class UnsubscribeVerifier
  def self.verify(param)
    Rails.application.message_verifier(:unsubscribe).verify(
      param, purpose: :newsletter
    )
  end

  def self.generate(id)
    Rails.application.message_verifier(:unsubscribe).generate(
      id, purpose: :newsletter
    )
  end
end
