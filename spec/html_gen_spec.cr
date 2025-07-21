require "./spec_helper"

describe "Runtime rendering" do
  it "renders a template with context at runtime", focus: true do
    slang = <<-SLANG
      doctype html
        html
          head
            meta name="viewport" content="width=device-width,initial-scale=1.0"
            title This is a title
      SLANG

    html = Slang.render_content(slang, {title: "This is a title"})
    expected_html = <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width,initial-scale=1.0">
          <title>This is a title</title>
        </head>
      </html>
      HTML
    html.should eq(expected_html)
  end
end
