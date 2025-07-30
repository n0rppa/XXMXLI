// Contact form handler
async function handleSubmit(event) {
    event.preventDefault();
    
    // Get form data
    const form = event.target;
    const formData = new FormData(form);
    
    // Validate form using existing validator
    if (!validateForm(form)) {
        return false;
    }
    
    try {
        // Prepare data for submission
        const data = {
            name: formData.get('name'),
            email: formData.get('email'),
            message: formData.get('message'),
            to: 'eemelipitkanen55@gmail.com'
        };
        // Send to Netlify function
        const response = await fetch('/.netlify/functions/send-email', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data)
        });
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        // Clear form on success
        form.reset();
        alert('Viesti lähetetty onnistuneesti!');
    } catch (error) {
        console.error('Error:', error);
        alert('Viestin lähetyksessä tapahtui virhe. Yritä uudelleen.');
    }
}
// Add form submission handler to all contact forms
document.addEventListener('DOMContentLoaded', () => {
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', handleSubmit);
    });
});