# frozen_string_literal: true

FactoryBot.define do
  factory :request, class: Eezee::Request do
    initialize_with { new(attributes) }

    after { ->(_req, _res, _err) { true } }
    before { ->(_req, _res, _err) {} }
    logger { true }
    headers do
      {
        'User-Agent' => 'Eezee',
        Token: 'Token 2b173033-45fa-459a-afba-9eea79cb75be'
      }
    end
    open_timeout { 2 }
    params do
      {
        user_id: 10,
        address_id: 15,
        state: 'Sao Paulo',
        country: 'Brazil'
      }
    end
    path { 'users/:user_id/addresses/:address_id' }
    payload do
      {
        street: 'Paulista Avenue',
        number: '123',
        state: 'Sao Paulo',
        country: 'Brazil'
      }
    end
    protocol { 'https' }
    raise_error { true }
    timeout { 10 }
    url { 'www.linqueta.com' }
  end
end
