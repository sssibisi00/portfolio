
// Mobile menu
const btn = document.getElementById('hamburger');
const mobile = document.getElementById('mobileMenu');
if(btn){
  btn.addEventListener('click', ()=> mobile.classList.toggle('show'));
}

// Typewriter on Home
document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('typewriter');
  if(!el) return;
  const phrases = [
    "Graduate / Junior Data Scientist/ Junior Data Analyst",
    "Python • Power BI • SQL • PostgreSQL • R Programming",
    "APIs • Pandas • Matplotlib • Scikit-learn"
  ];
  let i=0, j=0, deleting=false;
  const speed=80, pause=900;
  el.classList.add('cursor');
  (function type(){
    const s = phrases[i];
    if(!deleting){
      el.textContent = s.slice(0, ++j);
      if(j === s.length){ deleting=true; setTimeout(type, pause); }
      else setTimeout(type, speed);
    } else {
      el.textContent = s.slice(0, --j);
      if(j === 0){ deleting=false; i=(i+1)%phrases.length; setTimeout(type, speed); }
      else setTimeout(type, speed/2);
    }
  })();
});

//Histogram

const ctx = document.getElementById('skillsChart').getContext('2d');
new Chart(ctx, {
    type: 'bar',
    data: {
        labels: ["Power BI","Python","SQL","API","Pandas","Matplotlib"],
        datasets: [{
            label: 'Proficiency (%)',
            data: [80,85,95,80,80,75],
            backgroundColor: [
                '#f39c12','#3498db','#2ecc71','#f1c40f','#1abc9c','#e67e22'
            ],
            borderRadius: 8
        }]
    },
    options: {
        indexAxis: 'y',
        scales: {
            x: {
                beginAtZero: true,
                max: 100,
                ticks: {
                    font: {
                        size: 14,    // X-axis labels
                        weight: 'bold'
                    }
                }
            },
            y: {
                ticks: {
                    font: {
                        size: 16,    // Y-axis labels (skills)
                        weight: 'bold'
                    }
                }
            }
        },
        plugins: {
            legend: {
                labels: {
                    font: {
                        size: 14     // Legend text
                    }
                }
            },
            tooltip: {
                bodyFont: {
                    size: 14       // Tooltip text size
                },
                titleFont: {
                    size: 16       // Tooltip title size
                }
            }
        }
    }
});
