# db/seeds.rb

puts "Cleaning database..."

ClientSummary.destroy_all
EmailSummary.destroy_all
EmailMessage.destroy_all
EmailThread.destroy_all
Client.destroy_all
Accountant.destroy_all
Firm.destroy_all

puts "Creating firms..."

abc = Firm.create!(
  name: "ABC CPA",
  domain: "abc-cpa.com"
)

xyz = Firm.create!(
  name: "XYZ CPA",
  domain: "xyz-cpa.com"
)

puts "Creating accountants..."

john = Accountant.create!(
  firm: abc,
  name: "John Smith",
  email: "john@abc-cpa.com",
  password_digest: BCrypt::Password.create("password123"),
  role: "accountant"
)

mary = Accountant.create!(
  firm: abc,
  name: "Mary Johnson",
  email: "mary@abc-cpa.com",
  password_digest: BCrypt::Password.create("password123"),
  role: "admin"
)

bob_carter = Accountant.create!(
  firm: abc,
  name: "Bob Carter",
  email: "bob@abc-cpa.com",
  password_digest: BCrypt::Password.create("password123"),
  role: "accountant"
)

david = Accountant.create!(
  firm: xyz,
  name: "David Wilson",
  email: "david@xyz-cpa.com",
  password_digest: BCrypt::Password.create("password123"),
  role: "accountant"
)

_superuser = Accountant.create!(
  firm: abc,
  name: "System Admin",
  email: "admin@system.com",
  password_digest: BCrypt::Password.create("password123"),
  role: "superuser"
)

puts "Creating clients..."

alice = Client.create!(
  firm: abc,
  name: "Alice Brown",
  email: "alice@gmail.com",
  phone: "1111111111",
  status: "active"
)

bob = Client.create!(
  firm: abc,
  name: "Bob Green",
  email: "bob@gmail.com",
  phone: "2222222222",
  status: "active"
)

charlie = Client.create!(
  firm: xyz,
  name: "Charlie Davis",
  email: "charlie@gmail.com",
  phone: "3333333333",
  status: "active"
)

puts "Creating threads..."

# Alice — 6 threads (ABC CPA showcase client)
thread1 = EmailThread.create!(
  client: alice,
  conversation_id: "conv_001",
  subject: "W-2 Documents"
)

thread2 = EmailThread.create!(
  client: alice,
  conversation_id: "conv_002",
  subject: "1099-NEC Forms"
)

thread3 = EmailThread.create!(
  client: alice,
  conversation_id: "conv_003",
  subject: "Tax Deductions"
)

thread4 = EmailThread.create!(
  client: alice,
  conversation_id: "conv_004",
  subject: "Estimated Tax Payments"
)

thread5 = EmailThread.create!(
  client: alice,
  conversation_id: "conv_005",
  subject: "Schedule C Business Expenses"
)

thread6 = EmailThread.create!(
  client: alice,
  conversation_id: "conv_006",
  subject: "Home Office Deduction"
)

# Bob — 1 thread (ABC CPA)
thread7 = EmailThread.create!(
  client: bob,
  conversation_id: "conv_007",
  subject: "Filing Extension"
)

# Charlie — 2 threads (XYZ CPA)
thread8 = EmailThread.create!(
  client: charlie,
  conversation_id: "conv_008",
  subject: "Business Expenses"
)

thread9 = EmailThread.create!(
  client: charlie,
  conversation_id: "conv_009",
  subject: "Previous Year Returns"
)

puts "Creating messages..."

$graph_counter = 1
$msg_counter   = 1

def create_message(
  email_thread:,
  accountant:,
  from_email:,
  to_emails:,
  body:,
  sent_at:,
  subject:,
  cc_emails: nil
)
  EmailMessage.create!(
    email_thread:     email_thread,
    accountant:       accountant,
    graph_message_id: "graph_msg_#{$graph_counter.to_s.rjust(3, "0")}",
    message_id:       "msg_#{$msg_counter.to_s.rjust(3, "0")}",
    from_email:       from_email,
    to_emails:        to_emails,
    cc_emails:        cc_emails,
    subject:          subject,
    body:             body,
    sent_at:          sent_at
  )

  $graph_counter += 1
  $msg_counter   += 1
end

base_time = 10.days.ago

#
# Thread 1 — W-2 Documents (Resolved)
# John collects W-2. He closes saying "everything is in order" —
# a contradiction seeded here because Thread 2 shows 1099-NEC still missing.
#

create_message(
  email_thread: thread1,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  subject:      thread1.subject,
  body: "Hi Alice, to begin preparing your 2024 tax return I need your W-2 from " \
        "your primary employer. If you received W-2s from multiple employers please " \
        "send all of them. You can upload them securely through our portal.",
  sent_at: base_time
)

create_message(
  email_thread: thread1,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    john.email,
  subject:      thread1.subject,
  body: "Hi John, I have attached my W-2 from Acme Corp. That is my only employer " \
        "for 2024. I also do some freelance consulting work on the side but I am not " \
        "sure if I need to send anything for that separately.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread1,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  subject:      thread1.subject,
  body: "Thank you Alice, I have received your W-2. For your freelance income you " \
        "will need a 1099-NEC from each client who paid you more than $600 in 2024. " \
        "My colleague Mary will follow up with you on that separately.",
  sent_at: base_time + 3.hours
)

create_message(
  email_thread: thread1,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  subject:      thread1.subject,
  body: "I have reviewed your W-2 and everything looks in order. Your wage income " \
        "for 2024 is confirmed at $87,500. We have everything we need for this " \
        "portion of your return.",
  sent_at: base_time + 4.hours
)

create_message(
  email_thread: thread1,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    john.email,
  subject:      thread1.subject,
  body: "Great, thank you John.",
  sent_at: base_time + 5.hours
)

#
# Thread 2 — 1099-NEC Forms (Open)
# Mary requests 1099-NEC for freelance income. Alice waiting on payer.
# Contradiction with Thread 1: John closed saying "everything is in order"
# but 1099-NEC for Schedule C is still outstanding.
#

base_time += 1.day

create_message(
  email_thread: thread2,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread2.subject,
  body: "Hi Alice, I am following up on your freelance income as John mentioned. " \
        "To complete your Schedule C we need the 1099-NEC from Design Studio LLC " \
        "who paid you for consulting work in 2024. The IRS deadline for 1099-NEC " \
        "issuance is January 31 so you should have received it by now.",
  sent_at: base_time
)

create_message(
  email_thread: thread2,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread2.subject,
  body: "Hi Mary, I know I should have received it by now. I have emailed Design " \
        "Studio LLC twice asking for the 1099-NEC but they have not responded. " \
        "I will follow up again this week.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread2,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread2.subject,
  body: "If you do not receive the 1099-NEC by February 15 please let me know " \
        "and we can use your own records of the payment as a substitute. We cannot " \
        "finalize your Schedule C or self-employment tax calculation until this " \
        "is resolved.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread2,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread2.subject,
  body: "Understood. I am still trying to obtain it. I will send it the moment " \
        "I receive it.",
  sent_at: base_time + 3.hours
)

#
# Thread 3 — Tax Deductions (Mixed)
# John and Mary both involved. Charitable receipts submitted but
# home office confirmation and mileage log still unresolved.
#

base_time += 1.day

create_message(
  email_thread: thread3,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  cc_emails:    mary.email,
  subject:      thread3.subject,
  body: "Hi Alice, I want to capture all eligible deductions for your 2024 return. " \
        "You mentioned working from home. To claim the qualified home office deduction " \
        "under the regular method we need the square footage of your dedicated " \
        "workspace and your total home square footage. Please also confirm the space " \
        "is used exclusively and regularly for business.",
  sent_at: base_time
)

create_message(
  email_thread: thread3,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    john.email,
  subject:      thread3.subject,
  body: "Hi John, yes I have a dedicated home office. The room is 120 square feet " \
        "and my home is 1,400 square feet total. I use it exclusively for my " \
        "consulting work. I also made charitable donations this year and have receipts.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread3,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  cc_emails:    john.email,
  subject:      thread3.subject,
  body: "Alice, please send the charitable donation receipts and a record of any " \
        "cash donations. For vehicle expenses related to consulting work, do you " \
        "maintain a mileage log? We can deduct business mileage at $0.67 per mile " \
        "for 2024 under the IRS standard mileage rate.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread3,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread3.subject,
  body: "I am attaching my charitable donation receipts — $2,400 total across three " \
        "registered nonprofits. I do drive to client sites occasionally but I did not " \
        "keep a formal mileage log. Is there another way to document it?",
  sent_at: base_time + 3.hours
)

create_message(
  email_thread: thread3,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  cc_emails:    mary.email,
  subject:      thread3.subject,
  body: "Thank you for the donation receipts. The IRS requires contemporaneous " \
        "records for vehicle expenses so without a mileage log we cannot claim " \
        "the deduction this year. Please use a mileage tracking app in 2025. " \
        "I still need the home office square footage confirmed in writing.",
  sent_at: base_time + 4.hours
)

create_message(
  email_thread: thread3,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    john.email,
  subject:      thread3.subject,
  body: "Confirmed in writing: my dedicated office is 120 sq ft out of a total " \
        "1,400 sq ft home. I understand about the mileage log and will track it " \
        "properly going forward.",
  sent_at: base_time + 5.hours
)

create_message(
  email_thread: thread3,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread3.subject,
  body: "Received. Charitable donations and home office are now confirmed. The " \
        "1099-NEC is still outstanding per my separate thread — we cannot finalize " \
        "Schedule C until that arrives.",
  sent_at: base_time + 6.hours
)

create_message(
  email_thread: thread3,
  accountant:   bob_carter,
  from_email:   bob_carter.email,
  to_emails:    alice.email,
  cc_emails:    [ john.email, mary.email ],
  subject:      thread3.subject,
  body: "Hi Alice, I reviewed the documentation John and Mary have collected. " \
        "The home office calculation looks correct — 120/1,400 sq ft is well-documented. " \
        "One additional item: once the 1099-NEC from Design Studio LLC is in hand, " \
        "we should also verify whether your freelance income qualifies for the qualified " \
        "business income (QBI) deduction. I will follow up once that document arrives.",
  sent_at: base_time + 7.hours
)

#
# Thread 4 — Estimated Tax Payments (Resolved)
# Mary confirms all four quarterly payments. No open items.
#

base_time += 1.day

create_message(
  email_thread: thread4,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread4.subject,
  body: "Hi Alice, I need to confirm you made your Q4 2024 estimated tax payment " \
        "by January 15, 2025. As a self-employed consultant you are required to make " \
        "quarterly estimated payments under IRC Section 6654 to avoid an " \
        "underpayment penalty.",
  sent_at: base_time
)

create_message(
  email_thread: thread4,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread4.subject,
  body: "Yes, I paid $1,850 on January 12. I have attached the IRS payment " \
        "confirmation email for Q4.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread4,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread4.subject,
  body: "Confirmed. I have recorded all four 2024 quarterly payments: Q1 $1,600, " \
        "Q2 $1,700, Q3 $1,700, Q4 $1,850 — total $6,850. These will be credited " \
        "against your total tax liability. No underpayment penalty should apply.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread4,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread4.subject,
  body: "That is a relief. Thank you for tracking those.",
  sent_at: base_time + 3.hours
)

#
# Thread 5 — Schedule C Business Expenses (Open)
# John needs expense categorization. Alice still compiling contractor invoices.
#

base_time += 1.day

create_message(
  email_thread: thread5,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  subject:      thread5.subject,
  body: "Hi Alice, to complete your Schedule C I need all 2024 business expenses " \
        "categorized as: software subscriptions, professional development, equipment, " \
        "contractor payments, and other. Please attach invoices or receipts for any " \
        "item over $75 as the IRS may request substantiation.",
  sent_at: base_time
)

create_message(
  email_thread: thread5,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    john.email,
  subject:      thread5.subject,
  body: "Hi John, software and professional development are straightforward. The " \
        "contractor payments are the tricky part — I paid two freelancers via PayPal " \
        "and I am waiting on the transaction history export. Should be ready by " \
        "end of this week.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread5,
  accountant:   john,
  from_email:   john.email,
  to_emails:    alice.email,
  subject:      thread5.subject,
  body: "Note: if you paid any individual contractor more than $600 in 2024 you are " \
        "required to issue them a 1099-NEC by January 31. This is separate from " \
        "receiving your own 1099-NEC. Have you filed those?",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread5,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    john.email,
  subject:      thread5.subject,
  body: "I was not aware I needed to issue 1099-NECs. One contractor received just " \
        "under $600 so that should be fine, but the other received $1,200. I will " \
        "contact them immediately. I am still compiling the full expense list.",
  sent_at: base_time + 3.hours
)

#
# Thread 6 — Home Office Deduction (Duplicate request)
# Mary asks for home office documentation not realising John already handled it
# in Thread 3. Alice's confused reply exposes the coordination gap directly.
#

base_time += 1.day

create_message(
  email_thread: thread6,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread6.subject,
  body: "Hi Alice, I noticed we have not yet received documentation for your home " \
        "office deduction. Could you please send the square footage of your dedicated " \
        "workspace and your total home square footage? We also need confirmation that " \
        "the space is used exclusively and regularly for business.",
  sent_at: base_time
)

create_message(
  email_thread: thread6,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread6.subject,
  body: "Hi Mary, I am a little confused — I already sent this information to John " \
        "last week in our tax deductions thread. My office is 120 sq ft in a 1,400 " \
        "sq ft home and it is used exclusively for my consulting work. Did that not " \
        "reach you?",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread6,
  accountant:   mary,
  from_email:   mary.email,
  to_emails:    alice.email,
  subject:      thread6.subject,
  body: "Apologies for the duplication Alice — John and I were not coordinating on " \
        "this item. I have the information now: 120 sq ft office in 1,400 sq ft home " \
        "for an 8.57% business-use ratio. We will ensure better coordination before " \
        "reaching out to you again.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread6,
  accountant:   nil,
  from_email:   alice.email,
  to_emails:    mary.email,
  subject:      thread6.subject,
  body: "No problem. Please let me know if there is anything else — I just want to " \
        "make sure nothing falls through the cracks on my end.",
  sent_at: base_time + 3.hours
)

#
# Thread 7 — Filing Extension for Bob (Resolved, ABC CPA)
#

base_time = 8.days.ago

create_message(
  email_thread: thread7,
  accountant:   john,
  from_email:   john.email,
  to_emails:    bob.email,
  subject:      thread7.subject,
  body: "Hi Bob, given that we are still waiting on your K-1 from the partnership " \
        "I recommend we file a Form 4868 extension. This gives us until October 15 " \
        "to file without penalty. Note this extends the filing deadline but not the " \
        "payment deadline — any tax owed is still due April 15.",
  sent_at: base_time
)

create_message(
  email_thread: thread7,
  accountant:   nil,
  from_email:   bob.email,
  to_emails:    john.email,
  subject:      thread7.subject,
  body: "Yes please file the extension. I estimate I will owe roughly the same as " \
        "last year so I will make a payment by April 15 to avoid interest.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread7,
  accountant:   john,
  from_email:   john.email,
  to_emails:    bob.email,
  subject:      thread7.subject,
  body: "Extension filed. Confirmation number 2024-EXT-4481. Your new filing " \
        "deadline is October 15, 2025. Please confirm your address has not changed.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread7,
  accountant:   nil,
  from_email:   bob.email,
  to_emails:    john.email,
  subject:      thread7.subject,
  body: "Address is unchanged. Thank you John.",
  sent_at: base_time + 3.hours
)

create_message(
  email_thread: thread7,
  accountant:   john,
  from_email:   john.email,
  to_emails:    bob.email,
  subject:      thread7.subject,
  body: "Great. I will reach out once the K-1 arrives and we can proceed with the " \
        "full return at that point.",
  sent_at: base_time + 4.hours
)

#
# Thread 8 — Business Expenses for Charlie (Open, XYZ CPA)
#

base_time = 7.days.ago

create_message(
  email_thread: thread8,
  accountant:   david,
  from_email:   david.email,
  to_emails:    charlie.email,
  subject:      thread8.subject,
  body: "Hi Charlie, to prepare your Schedule C I need your 2024 business expense " \
        "records. Please include travel, meals (50% deductible), equipment, and any " \
        "subcontractor payments. Attach receipts for substantiation.",
  sent_at: base_time
)

create_message(
  email_thread: thread8,
  accountant:   nil,
  from_email:   charlie.email,
  to_emails:    david.email,
  subject:      thread8.subject,
  body: "Hi David, travel and meals are easy to compile but I am still waiting on " \
        "invoices from two vendors. Should have everything by next week.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread8,
  accountant:   david,
  from_email:   david.email,
  to_emails:    charlie.email,
  subject:      thread8.subject,
  body: "Please send what you have so far. Also confirm whether meal expenses were " \
        "for client entertainment — those are 50% deductible under the Tax Cuts and " \
        "Jobs Act rules.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread8,
  accountant:   nil,
  from_email:   charlie.email,
  to_emails:    david.email,
  subject:      thread8.subject,
  body: "All meal expenses were for client meetings. I will send the available " \
        "receipts today and follow up with the two outstanding vendor invoices.",
  sent_at: base_time + 3.hours
)

#
# Thread 9 — Previous Year Returns for Charlie (Resolved, XYZ CPA)
#

base_time = 6.days.ago

create_message(
  email_thread: thread9,
  accountant:   david,
  from_email:   david.email,
  to_emails:    charlie.email,
  subject:      thread9.subject,
  body: "Hi Charlie, I need copies of your 2022 and 2023 tax returns to carry forward " \
        "the net operating loss from 2022. Please send them in PDF format.",
  sent_at: base_time
)

create_message(
  email_thread: thread9,
  accountant:   nil,
  from_email:   charlie.email,
  to_emails:    david.email,
  subject:      thread9.subject,
  body: "Hi David, I have attached both returns. The 2022 return shows the NOL " \
        "on the final page.",
  sent_at: base_time + 1.hour
)

create_message(
  email_thread: thread9,
  accountant:   david,
  from_email:   david.email,
  to_emails:    charlie.email,
  subject:      thread9.subject,
  body: "Confirmed. The 2022 NOL is $18,400. Under IRC Section 172 you can carry " \
        "forward 80% of this amount to offset 2024 taxable income. I will incorporate " \
        "this into your 2024 return.",
  sent_at: base_time + 2.hours
)

create_message(
  email_thread: thread9,
  accountant:   david,
  from_email:   david.email,
  to_emails:    charlie.email,
  subject:      thread9.subject,
  body: "Both prior-year returns reviewed and all NOL carryforward amounts confirmed. " \
        "This item is complete.",
  sent_at: base_time + 3.hours
)

create_message(
  email_thread: thread9,
  accountant:   nil,
  from_email:   charlie.email,
  to_emails:    david.email,
  subject:      thread9.subject,
  body: "Great. Let me know what else you need for the 2024 return.",
  sent_at: base_time + 4.hours
)

puts "Done! Created:"
puts "  2 firms, 5 accountants, 3 clients"
puts "  9 email threads (6 for Alice, 1 for Bob, 2 for Charlie)"
puts "  #{EmailMessage.count} email messages"
