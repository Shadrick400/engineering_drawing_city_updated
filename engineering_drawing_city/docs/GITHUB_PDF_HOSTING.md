# Hosting Engineering Drawing City PDFs on GitHub

Engineering Drawing City can open PDF files from GitHub Raw URLs inside its existing PDF reader.

## 1. Create a materials repository

1. Create a separate GitHub repository for the learning materials.
2. Set the repository to **Public**. The app's unauthenticated HTTP request cannot read files from a private repository without adding a separate authenticated download service.
3. Add folders such as `books/` and `past-papers/` to keep the files organised.
4. Upload only PDFs that you own or are authorised to distribute.

## 2. Copy the Raw URL

1. Open the PDF file in the GitHub repository.
2. Select **Raw**.
3. Copy the resulting URL. It should look like:

   `https://raw.githubusercontent.com/USERNAME/REPOSITORY/BRANCH/books/example.pdf`

4. In Engineering Drawing City's Admin dashboard, add a book or past paper and paste this URL into the **GitHub Raw PDF URL** field.

Do not paste the normal GitHub `blob` page URL. The app expects a direct Raw URL ending in `.pdf`.

## 3. Important access and privacy limitation

A public GitHub Raw URL is public. Anyone who obtains it may open, copy, or download the PDF outside Engineering Drawing City. The app's subscription check controls access through the normal app interface; it does **not** make a public GitHub file private or enforce subscription access at GitHub's servers.

The in-app reader does not display a download button, but this is not DRM and cannot prevent screenshots, copying, browser access, or downloads by a determined user. Do not use public GitHub hosting for confidential or restricted documents.

## 4. Existing Firebase Storage documents

Existing `gs://.../learning_materials/...` links remain supported by the reader during migration. New GitHub Raw links can be added without changing the Firestore document structure because both are stored in the existing `fileUrl` field.

## 5. Reader limits

The app downloads the PDF bytes to render them with the existing PDF viewer. The current maximum accepted document size is 100 MB, and the request times out after 60 seconds. Large files may be slow on mobile data.
