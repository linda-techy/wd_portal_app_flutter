class DesignAgreementTemplate {
  static const String htmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Design Partnership Agreement</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap');
        
        body {
            font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #1f2937;
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
            background-color: #ffffff;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 40px;
            border-bottom: 2px solid #f3f4f6;
            padding-bottom: 20px;
        }
        .logo {
            font-size: 28px;
            font-weight: 800;
            color: #0f172a;
            letter-spacing: -0.5px;
        }
        .logo span {
            color: #2563eb; /* Professional Blue */
        }
        .welcome-text {
            font-size: 14px;
            color: #6b7280;
            font-weight: 500;
        }
        h1 {
            font-size: 24px;
            color: #111827;
            text-align: center;
            margin-bottom: 10px;
        }
        h2 {
            font-size: 18px;
            color: #1f2937;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 10px;
            margin-top: 40px;
            margin-bottom: 20px;
            font-weight: 700;
        }
        h3 {
            font-size: 16px;
            color: #2563eb;
            margin-top: 25px;
            margin-bottom: 15px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        p, li {
            font-size: 14px;
            color: #374151;
            margin-bottom: 10px;
        }
        ul, ol {
            padding-left: 25px;
        }
        li {
            margin-bottom: 8px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            font-size: 13px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        th, td {
            border: 1px solid #e5e7eb;
            padding: 12px 15px;
            text-align: left;
            vertical-align: top;
        }
        th {
            background-color: #f9fafb;
            font-weight: 600;
            color: #111827;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
        }
        .highlight-row {
            background-color: #ffffff;
        }
        .highlight-row:nth-child(even) {
            background-color: #f9fafb;
        }
        .page-break {
            page-break-before: always;
            margin-top: 50px;
            border-top: 1px dashed #d1d5db;
            padding-top: 30px;
        }
        .signature-box {
            margin-top: 60px;
            display: flex;
            justify-content: space-between;
        }
        .sign-line {
            width: 40%;
            border-top: 1px solid #9ca3af;
            padding-top: 10px;
            text-align: center;
            font-size: 12px;
            color: #6b7280;
        }
        .emphasis {
            font-weight: 600;
            color: #111827;
        }
        .quote-box {
            background-color: #eff6ff;
            border-left: 4px solid #2563eb;
            padding: 15px;
            margin: 20px 0;
            font-style: italic;
            color: #1e40af;
            font-size: 13px;
        }
    </style>
</head>
<body>

    <!-- Page 1: Agreement & Partnership -->
    <div class="header">
        <div class="logo"><span>Walldot</span> Builders</div>
        <div class="welcome-text">Building Your Future, Together.</div>
    </div>

    <h1>Premium Design & Project Management Partnership</h1>
    <p style="text-align: center; color: #6b7280; font-size: 12px; margin-top: -5px;">Powered by Walldot Builders LLP</p>
    <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 20px 0;">

    <p>This agreement marks the beginning of a collaborative journey between:</p>
    <ol>
        <li><strong>Walldot Builders LLP</strong>, your technology-driven construction partner, dedicated to transparency, precision, and excellence.</li>
        <li><strong>{{CLIENT_NAME}}</strong>, our valued partner, for whom we are committed to delivering an exceptional end-to-end home building experience.</li>
    </ol>

    <div class="quote-box">
        "We believe that building a home should be a joyful milestone, not a stressful task. Our partnership is built on mutual trust, clear communication, and shared goals."
    </div>

    <h3>Your Role as Our Partner</h3>
    <p>To ensure your vision is perfectly captured and executed, we invite you to:</p>
    <ul>
        <li><strong>Share Your Dream:</strong> Clearly detail your aspirations for design, budget, and timelines. These will serve as our north star.</li>
        <li><strong>Collaborate Actively:</strong> Provide timely and detailed feedback during design iterations. Your input is crucial to freezing designs (Plans, Elevations, 3D) efficiently.</li>
        <li><strong>Enable Progress:</strong> Ensure timely release of payments to maintain the project's momentum and avoid cost escalations.</li>
        <li><strong>Engage with Us:</strong> Participate in VR walkthroughs and project discussions to make informed decisions.</li>
        <li><strong>Trust the Process:</strong> Empower Walldot Builders to coordinate with expert designers and contractors on your behalf, ensuring a cohesive build.</li>
    </ul>

    <h3>Our Commitment to Excellence</h3>
    <p>Walldot Builders is dedicated to revolutionizing your building experience through technology and expertise:</p>
    <ul>
        <li><strong>Seamless Technology:</strong> We leverage cutting-edge tools like <em>Virtual Reality</em>, <em>Pro Tracker</em>, and our <em>e-Commerce platform</em> to give you complete control and visibility.</li>
        <li><strong>Expert Team:</strong> We curate and appoint the finest Architects and Contractors tailored to your project's specific needs.</li>
        <li><strong>Transparency & Quality:</strong>
            <ul>
                <li><strong>Immersive VR:</strong> Experience your home before a single brick is laid.</li>
                <li><strong>Real-Time Updates:</strong> Track progress daily via our Site App with BOQ-level precision.</li>
                <li><strong>Quality Assurance:</strong> We ensure only top-tier materials and workmanship are used.</li>
                <li><strong>Budget Protection:</strong> Our Active Budget Control ensures your project stays within the financial boundaries we set together.</li>
            </ul>
        </li>
    </ul>

    <div class="signature-box">
        <div class="sign-line">Authorized Signatory<br>Walldot Builders LLP</div>
        <div class="sign-line">Partner Signature<br>{{CLIENT_NAME}}</div>
    </div>

    <div class="page-break"></div>

    <!-- Page 2: Design Stage Scope -->
    <div class="header">
        <div class="logo"><span>Walldot</span> Builders</div>
        <div class="welcome-text">Design Phase</div>
    </div>

    <h2>The Design Experience</h2>
    <p>Our design phase is where your ideas take shape. We combine creativity with engineering precision to create a home that is beautiful, functional, and buildable.</p>

    <h3>What We Deliver (Premium Package)</h3>
    <p>We go beyond standard drawings to provide a comprehensive design suite:</p>
    <ul>
        <li><strong>Architectural Mastery:</strong> Detailed Plans with Building Performance Indices (BPI), Elevations, Sections, and Finishing Schedules.</li>
        <li><strong>Visual Immersion:</strong>
            <ul>
                <li><strong>3 VR Sessions:</strong> Dedicated sessions for Structure, Interiors, and Finishes.</li>
                <li><strong>3D Renders:</strong> Up to 10 external views and 1 internal view per room.</li>
                <li><strong>360° Web Walkthrough:</strong> Share your future home with friends and family online.</li>
            </ul>
        </li>
        <li><strong>Engineering Precision:</strong>
            <ul>
                <li>Structural Design & Diagrams.</li>
                <li>MEP (Mechanical, Electrical, Plumbing) Diagrams.</li>
                <li>50+ Detailed Engineering & Working Drawings.</li>
            </ul>
        </li>
        <li><strong>Holistic Planning:</strong>
            <ul>
                <li>Detailed Interior Design.</li>
                <li>Landscape Architecture.</li>
                <li>Sustainability & Smart Home Planning.</li>
            </ul>
        </li>
        <li><strong>Regulatory Support:</strong> Coordination and preparation of all drawings required for statutory approvals and sanctions.</li>
        <li><strong>Financial Clarity:</strong> A detailed Bill of Quantities (BoQ) with itemized costing, ready for precise tracking.</li>
    </ul>

    <div class="quote-box">
        <strong>Note on Iterations:</strong> To keep the project moving efficiently, we include up to 5 iterations for plans and elevations. We find this is usually sufficient to reach perfection!
    </div>

    <div class="page-break"></div>

    <!-- Page 3: Timeline -->
    <div class="header">
        <div class="logo"><span>Walldot</span> Builders</div>
        <div class="welcome-text">Project Roadmap</div>
    </div>

    <h2>Estimated Timeline</h2>
    <p>We value your time. This roadmap outlines the typical journey from concept to completion.</p>
    
    <table>
        <thead>
            <tr>
                <th>Phase</th>
                <th>Key Milestones</th>
                <th>Estimated Duration</th>
            </tr>
        </thead>
        <tbody>
            <tr class="highlight-row">
                <td><strong>1. Conceptualization</strong></td>
                <td>Site Plan, Basic Floor Plan</td>
                <td>1-2 Weeks</td>
            </tr>
            <tr class="highlight-row">
                <td><strong>2. Detailed Design</strong></td>
                <td>Plan Drawings, Vasthu, Elevations, <strong>VR Visualization</strong>, Structural Design, Cost Estimation</td>
                <td>2-4 Weeks</td>
            </tr>
            <tr class="highlight-row">
                <td><strong>3. Statutory Approval</strong></td>
                <td>Submission of Detailed Drawings for Approval</td>
                <td>4 Weeks</td>
            </tr>
            <tr class="highlight-row">
                <td><strong>4. Land Development</strong></td>
                <td>Site Cleaning, Fencing, Boundary Walls</td>
                <td>1-4 Weeks</td>
            </tr>
            <tr class="highlight-row">
                <td><strong>5. Construction</strong></td>
                <td>End-to-End Execution, Daily Supervision, Quality Checks</td>
                <td>6-8 Months</td>
            </tr>
            <tr class="highlight-row">
                <td><strong>6. Interiors</strong></td>
                <td>Interior Design, VR Visualization, Execution</td>
                <td>2-3 Months</td>
            </tr>
            <tr class="highlight-row">
                <td><strong>7. Handover</strong></td>
                <td>Completion Certificate, Final Inspections</td>
                <td>Included in Construction</td>
            </tr>
        </tbody>
    </table>

    <p style="font-size: 12px; color: #6b7280;">*Timelines are estimates and depend on timely decisions and payments. We strive to meet these targets to get you into your new home as planned.</p>

    <div class="page-break"></div>

    <!-- Page 4: Investment -->
    <div class="header">
        <div class="logo"><span>Walldot</span> Builders</div>
        <div class="welcome-text">Investment Structure</div>
    </div>

    <h2>Fee & Payment Schedule</h2>
    
    <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
        <p style="margin: 0; font-size: 16px;"><strong>Design Fee:</strong> <span style="color: #2563eb; font-size: 18px; font-weight: bold;">Rs. {{DESIGN_FEE_PER_SFT}} /- per sq. ft.</span></p>
        <p style="margin: 5px 0 0 0; font-size: 13px; color: #6b7280;">Based on a total project area of <strong>{{TOTAL_PROJECT_AREA}} sq. ft.</strong> (Plus applicable GST)</p>
    </div>

    <h3>Payment Milestones</h3>
    <table>
        <thead>
            <tr>
                <th style="width: 10%;">#</th>
                <th style="width: 60%;">Milestone</th>
                <th style="width: 30%;">Payment</th>
            </tr>
        </thead>
        <tbody>
            <tr class="highlight-row">
                <td>1</td>
                <td><strong>Project Kickoff</strong><br><span style="font-size: 11px; color: #6b7280;">Advance payment to commence work</span></td>
                <td>Rs. {{ADVANCE_PAYMENT_RATE}} / sq. ft.</td>
            </tr>
            <tr class="highlight-row">
                <td>2</td>
                <td><strong>Design Finalization</strong><br><span style="font-size: 11px; color: #6b7280;">Prior to VR Walkthrough & Statutory Submission</span></td>
                <td>Rs. {{PRELIMINARY_DESIGN_PAYMENT_RATE}} / sq. ft.</td>
            </tr>
            <tr class="highlight-row">
                <td>3</td>
                <td><strong>Interior Design Start</strong><br><span style="font-size: 11px; color: #6b7280;">Before commencing detailed interior planning</span></td>
                <td>Rs. {{INTERIOR_DESIGN_PAYMENT_RATE}} / sq. ft.</td>
            </tr>
        </tbody>
    </table>

    <h3>Banking Details</h3>
    <div style="border: 1px solid #e5e7eb; padding: 15px; border-radius: 6px; display: inline-block; min-width: 300px;">
        <p><strong>Account Name:</strong> Walldot Builders LLP</p>
        <p><strong>Bank:</strong> Central Bank of India</p>
        <p><strong>Branch:</strong> Kumarapuram</p>
        <p><strong>Account No:</strong> 3496335633</p>
        <p><strong>IFSC Code:</strong> CBIN0281283</p>
    </div>

    <p style="margin-top: 30px; font-size: 12px; color: #9ca3af; text-align: center;">Walldot Builders LLP | Transforming Visions into Reality</p>

</body>
</html>
''';
}
