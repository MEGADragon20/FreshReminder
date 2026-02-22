from .models import db, Cart, CartItem, Product
import smtplib
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from weasyprint import HTML
import tempfile
import os

def compute_cart_price(cart_id):
    total_price = 0

    cart = Cart.query.get(cart_id)
    if not cart:
        return 0

    cart_items = CartItem.query.filter_by(cart_id=cart_id).all()

    for item in cart_items:
        product = Product.query.get(item.product_id)
        if product:
            total_price += item.quantity * product.price
    return total_price




def send_receipt_email(to_email, from_email, items, total_price):
    # ---- 1. Create HTML email body ----
    html_body = f"""
    <html>
        <body>
            <h2>Thank you for using our services!</h2>
            <p>We truly appreciate your purchase.</p>
            <p><strong>Total Price:</strong> ${total_price}</p>
            <p>Please find your detailed receipt attached as a PDF.</p>
        </body>
    </html>
    """

    # ---- 2. Create PDF from HTML template ----
    pdf_template = """
    <html>
        <body>
            <h1>Receipt</h1>
            <p>ITEMS</p>
        </body>
    </html>
    """

    item_lines = ""
    for item in items:
        item_lines += f"{item['name']} {item['quantity']} {item['price']}<br>"

    pdf_html = pdf_template.replace("ITEMS", item_lines)

    # Generate PDF in temporary file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
        HTML(string=pdf_html).write_pdf(tmp_file.name)
        tmp_file_path = tmp_file.name

    # ---- 3. Build Email ----
    msg = MIMEMultipart()
    msg["Subject"] = "Receipt for your purchase"
    msg["From"] = from_email
    msg["To"] = to_email

    # Attach HTML body
    msg.attach(MIMEText(html_body, "html"))

    # Attach PDF
    with open(tmp_file_path, "rb") as f:
        pdf_attachment = MIMEApplication(f.read(), _subtype="pdf")
        pdf_attachment.add_header(
            "Content-Disposition",
            "attachment",
            filename="receipt.pdf",
        )
        msg.attach(pdf_attachment)

    # ---- 4. Send Email ----
    with smtplib.SMTP("localhost") as server:
        server.sendmail(from_email, [to_email], msg.as_string())

    # Cleanup
    os.remove(tmp_file_path)
