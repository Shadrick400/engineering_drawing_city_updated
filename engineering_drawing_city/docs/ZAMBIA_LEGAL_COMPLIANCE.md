# Zambia legal and compliance checklist — Engineering Drawing City

**Prepared:** 5 November 2026  
**Scope:** A Zambia-facing educational mobile application that collects student account details, hosts or embeds learning materials, provides an AI feature, and intends to sell a monthly digital subscription.

> This is a practical product checklist, not legal advice or a legal opinion. Applicability can depend on the operator's legal status, how the service is marketed, where data is hosted, and how the content is sourced. Have a Zambian lawyer and the relevant regulators confirm the position before public commercial launch.

## 1. Data Protection Act, 2021 (Act No. 3 of 2021)

This is directly relevant because the app processes student names, email addresses, phone numbers, programme/year details, account identifiers, activity/progress, and potentially payment references.

Key duties to plan for:

- Process personal data lawfully, fairly and transparently; state the purposes; collect only what is needed; keep data accurate; limit retention; and protect it with appropriate security measures (sections 12–13).
- Register as a data controller and/or data processor unless a statutory exemption applies (sections 19–21). The Data Protection Commission's guidance says the registration regime applies to individuals and entities that process personal data.
- Appoint a Data Protection Officer (section 48), maintain processing records (section 45), and carry out a data-protection impact assessment where the type and risk of processing trigger section 46.
- Protect data using appropriate technical and organisational safeguards, including access controls and encryption (section 47).
- Notify the Data Protection Commissioner within 24 hours of a personal-data security breach, and notify affected data subjects as soon as practicable (section 49).
- Give users a clear privacy notice and provide processes for access, correction, erasure, objection/restriction, portability and complaints (Part IX, sections 58–68).
- If the app processes personal data of a child or vulnerable person, obtain and verify the required consent from a parent, legal guardian or person exercising parental responsibility (section 17).
- Section 70(1) requires personal data to be processed and stored on a server or data centre located in Zambia, subject to the Act's limited exceptions. Section 71 controls transfers outside Zambia. The Data Protection Commission's registration portal separately asks applicants to apply for authorisation where data will be stored or transferred outside Zambia. Check the actual Firebase/Google project region and every processor's location before launch; do not assume ordinary cloud hosting automatically satisfies the Act.

**Product actions:** publish a privacy notice before collecting information; record the purposes and lawful basis for each field; collect only essential profile fields; set retention/deletion rules; appoint a DPO; document Firebase and other processors; check cross-border transfer authorisation; and prepare a breach-response procedure that can meet the 24-hour regulator notification requirement.

Official sources:
- [Data Protection Act No. 3 of 2021 — National Assembly of Zambia](https://www.parliament.gov.zm/sites/default/files/documents/acts/Act%20No.%203%20The%20Data%20Protection%20Act%202021_0.pdf)
- [Data Protection Commission — FAQ](https://www.dataprotection.gov.zm/faq/)
- [Data Protection Commission — registration portal](https://registration.dataprotection.gov.zm/)
- [Registration guidance for data controllers and processors](https://www.dataprotection.gov.zm/wp-content/uploads/2025/03/Guide_Registration-of-Data-Controllers-and-Processors.pdf)

## 2. Electronic Communications and Transactions Act, 2021 (Act No. 4 of 2021)

This is relevant to the app's online subscription sales, electronic acceptance, account notices and digital records.

Section 63 requires an electronic supplier, where applicable, to make key information available in the app or other sales platform. This includes the supplier's full name and legal status, physical address and telephone number, website and email, registration details if it is a legal person, service description, full price and other costs, payment method, terms, delivery/performance timing, transaction records, refund policy, privacy/security information and minimum duration for recurring services. It also requires the customer to be able to review the transaction, correct mistakes and withdraw before placing the order. Section 63(8) refers to registration with the Authority in the prescribed manner; confirm the applicable supplier-registration process with ZICTA before selling subscriptions.

Other important points:

- Section 21 recognises agreements concluded wholly or partly through data messages.
- Section 66 generally gives consumers a seven-day right to cancel a service transaction without penalty, with a full refund within 30 days if already paid. The Act lists exceptions, including services fully performed with the consumer's consent before the seven-day period ends and certain streamed/downloaded audio/video/software transactions. The exact treatment of this app's subscription must be checked by a Zambian lawyer; do not assume that a blanket “no refunds” clause overrides statutory rights.
- Section 63(5) requires a sufficiently secure payment system.
- Section 65 regulates commercial electronic communications and consent/opt-out requirements.

**Product actions:** show the legal supplier/operator identity and contact details; disclose the K50 price, subscription duration, renewal approach and all charges before payment; provide terms and privacy policy; give the student a final review/confirmation step; issue a transaction record/receipt; provide a working support and complaint route; and write a cancellation/refund policy that preserves statutory rights.

Official sources:
- [Electronic Communications and Transactions Act No. 4 of 2021 — National Assembly of Zambia](https://www.parliament.gov.zm/sites/default/files/documents/acts/Act%20No.%204%20of%202021%2C%20The%20Electronic%20Communications%20and%20Transactions_0.pdf)
- [ZICTA — legislation](https://www.zicta.zm/resources/legislation)

## 3. Competition and Consumer Protection Act, 2010 (Act No. 24 of 2010), as amended

This applies to commercial activity and consumer-facing services in Zambia. The 2023 amendment is Act No. 21 of 2023.

The Act addresses unfair trading practices, false or misleading representations, unconscionable conduct and the display of disclaimers. Do not rely on blanket disclaimers or misleading claims about features, access, payment, refunds or accreditation. The exact enforceability of subscription clauses should be reviewed against the Act and the Electronic Communications and Transactions Act rather than assuming a general unfair-terms test.

**Product actions:** make the price and service limits clear; describe what a K50 subscription actually unlocks; do not claim that the app or its courses are accredited unless that is true; explain outages and support arrangements; and have cancellation, suspension and refund wording reviewed for fairness.

Official sources:
- [Competition and Consumer Protection Act, 2010 — Parliament of Zambia](https://www.parliament.gov.zm/node/3351)
- [Competition and Consumer Protection (Amendment) Act, 2023 — ZambiaLII](https://zambialii.org/akn/zm/act/2023/21/eng%402023-12-26)
- [CCPC — online shopping and consumer cautions](https://www.ccpc.org.zm/details/94)

## 4. Copyright and Performance Rights Act, 1994 (Chapter 406), as amended

This is important for engineering drawings, lecture videos, diagrams, books, PDFs, past examination papers, photographs and cover images. Copyright owners generally control reproduction, publication and communication of protected works to the public (including the controlled acts in section 17).

**Product actions:** only upload material created by the app operator or material for which the operator has permission/licences; keep records of permissions; require admins to confirm rights before publishing; provide a copyright complaint/takedown contact and a process to disable disputed material promptly. Do not assume that a work is free to upload merely because it is educational, available online, or described as a past paper. Educational fair-dealing exceptions are limited and should not be treated as a general licence for a paid content library.

Official source:
- [Copyright and Performance Rights Act, Chapter 406 — ZambiaLII](https://zambialii.org/akn/zm/act/1994/44/eng%402010-08-16)

## 5. Cyber Security Act, 2025 (Act No. 3 of 2025) and Cyber Crimes Act, 2025 (Act No. 4 of 2025)

These replaced the 2021 Cyber Security and Cyber Crimes Act framework and commenced on 12 May 2025. The Cyber Crimes Act covers offences involving unauthorised access/interference, computer-related fraud and identity-related crimes, among other offences. The Cyber Security Act establishes the national cyber-security framework and regulates specified cyber-security service activities and critical information infrastructure.

An ordinary educational app is not automatically a licensed cyber-security service provider. However, the app operator and its users should avoid unauthorised access, credential sharing, tampering, fraud and malicious activity, and the operator should protect accounts and personal data.

**Product actions:** remove credentials from source code; use Firebase Authentication and server-side role checks; enable least-privilege access; secure Firestore and Storage rules; protect administrative accounts with strong authentication; log sensitive admin actions; and maintain backups and an incident-response plan.

Official sources:
- [Cyber Security Act, 2025 — ZambiaLII](https://zambialii.org/akn/zm/act/2025/3/eng%402025-04-15)
- [Cyber Crimes Act, 2025 — ZambiaLII](https://zambialii.org/akn/zm/act/2025/4/eng%402025-04-15)
- [Cyber Security Act (Commencement) Order, 2025](https://zambialii.org/akn/zm/act/si/2025/22/eng%402025-05-12)
- [Cyber Crimes Act (Commencement) Order, 2025](https://zambialii.org/akn/zm/act/si/2025/23/eng%402025-05-12)

## 6. Operator information still required before launch

Do not publish guessed or placeholder business information. The app's sales/legal screen should use the actual operator details:

- Full legal name of the person or entity supplying the service.
- Legal status (individual/sole trader, registered business name, company, or other).
- Physical business/contact address in Zambia and address for legal notices.
- Correct Zambian telephone number and monitored support email.
- If a company or legal person: PACRA registration number, place of registration and required office-bearer information.
- ZICTA supplier-registration position under the ECT Act.
- Data Protection Commission controller/processor registration and DPO contact.
- Confirmed content ownership/licensing and copyright complaints contact.

The original source contained inconsistent contact information. The country code in the app settings has been corrected to +260 using the Zambian number already present elsewhere in the app, but the operator must confirm that the number and support email are current and authorised for customer support before launch.

## 7. Release checklist

- [ ] Confirm legal operator name, legal status, address and support contacts.
- [ ] Confirm Data Protection Commission registration category and complete registration if required.
- [ ] Appoint a DPO and publish a privacy notice.
- [ ] Check Firebase/Google data locations and cross-border transfer requirements.
- [ ] Prepare data-subject request and 24-hour breach-response procedures.
- [ ] Confirm ZICTA registration requirements for the electronic supplier.
- [ ] Review subscription, cancellation, refund, renewal and suspension terms.
- [ ] Display all required supplier information and total price before purchase.
- [ ] Confirm permission/licences for every video, book, past paper, drawing and cover image.
- [ ] Replace hardcoded admin credentials and enforce server-side access control.
- [ ] Have a Zambian lawyer review the final in-app privacy notice, terms and payment/refund policy.

