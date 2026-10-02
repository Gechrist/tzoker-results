import { track, bindValue, type Tracked } from 'ripple';

export function App() @{
	const count: Tracked<number> = track(2);
	let winningNumbers: Tracked<number[]> = track([]);
	let tzoker: Tracked<number[]> = track([]);
	let errorMessage: Tracked<boolean> = track(false);
	let isLoading: Tracked<boolean> = track(false);

	const getMostCommonNumbers = (numbers: number[], limit: number) => {
		const frequencyMap: Record<number, number> = {};
		numbers.forEach((num) => {
			frequencyMap[num] = (frequencyMap[num] || 0) + 1;
		});

		const sortedNumbers = Object.entries(frequencyMap).sort((a, b) => b[1] - a[1]).map(
			([num]) => parseInt(num),
		);

		return sortedNumbers.slice(0, limit);
	};

	const callAPI = async () => {
		isLoading.value = true;
		errorMessage.value = false;
		if (count.value < 2) {
			isLoading.value = false;
			errorMessage.value = true;
			return;
		}

		try {
			const response = await fetch(
				`https://api.opap.gr/draws/v3.0/5104/last-result-and-active`,
				{
					method: 'GET',
					headers: {
						'Content-Type': 'application/json',
					},
				},
			);
			let parsedResponse = await response.json();

			const response2 = await fetch(
				`https://api.opap.gr/draws/v3.0/5104/draw-id/
						${
					parsedResponse.last.drawId - (count.value - 1)
				}
					/${parsedResponse.last.drawId}
					`,
				{
					method: 'GET',
					headers: {
						'Content-Type': 'application/json',
					},
				},
			);
			let parsedResponse2 = await response2.json();
			parsedResponse2.content.forEach((draw: any) => {
				winningNumbers.value = [
					...winningNumbers.value,
					...Object.values(draw.winningNumbers.list) as number[],
				];
				tzoker.value = [
					...tzoker.value,
					...Object.values(draw.winningNumbers.bonus) as number[],
				];
			});
			winningNumbers.value = getMostCommonNumbers(winningNumbers.value, 5);
			tzoker.value = getMostCommonNumbers(tzoker.value, 1);

			isLoading.value = false;
		} catch (error) {
			isLoading.value = false;
			console.error('Error fetching winning numbers:', error);
			errorMessage.value = true;
		}
	};

	<>
		<div class="app">
			<div class="card">
				<h2>Συχνά νούμερα Τζόκερ</h2>

				<div class="counter">
					<input
						onKeydown={(e: KeyboardEvent) => {
							if (e.key === 'Enter') {
								callAPI();
							}
						}}
						min="2"
						style={{ width: '3rem', textAlign: 'center' }}
						type="number"
						ref={bindValue(count)}
					/>
					<p>{'τελευταίες κληρώσεις'}</p>
				</div>
				<button onClick={() => callAPI()}>Λήψη</button>

				@if (isLoading.value) {
					<div class="loading">
						<p>Φόρτωση...</p>
					</div>
				}

				@if (!errorMessage.value && !isLoading.value) {
					<div class="results">
						<p>Νικητήριοι Αριθμοί: {winningNumbers.value}</p>
						<p>Τζόκερ: {tzoker.value}</p>
					</div>
				}

				@if (errorMessage.value) {
					<div class="error">
						<p>Κάτι πήγε στραβά. Δοκιμάστε ξανά αργότερα.</p>
					</div>
				}
			</div>
		</div>
		<style>
			:global(body) {
				margin: 0;
			}

			.app {
				box-sizing: border-box;
				min-height: 100dvh;
				display: flex;
				justify-content: center;
				align-items: center;
				background: radial-gradient(circle at top left, #1a1c2b, #0d0e17 85%);
				color: #f2f4f8;
				font-family: 'Inter', 'Segoe UI', sans-serif;
				letter-spacing: 0.25px;
				padding: 1rem;
			}

			.card {
				background: rgba(18, 19, 29, 0.75);
				padding: 2rem 1rem;
				border-radius: 1rem;
				text-align: center;
				border: 1px solid rgba(255, 255, 255, 0.1);
				backdrop-filter: blur(10px);
				box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
				max-width: 100%;
				box-sizing: border-box;
			}

			.loading {
				margin-top: 1.5rem;
				text-align: center;
			}

			.error {
				margin-top: 1.5rem;
				text-align: center;
				color: #ff4d4f;
			}

			.results {
				margin-top: 1.5rem;
				text-align: left;
				background-color: rgba(31, 32, 46, 0.9);
				padding: 0.5rem;
				border-radius: 0.75rem;
				overflow-x: auto;
			}

			.counter {
				display: flex;
				align-items: center;
				justify-content: center;
				gap: 1rem;
				margin: 1.5rem 0;
			}

			button {
				background-color: rgba(58, 58, 72, 0.9);
				color: #f2f4f8;
				font-size: 1.1rem;
				border: 1px solid rgba(255, 255, 255, 0.1);
				border-radius: 0.75rem;
				padding: 0.5rem 1rem;
				cursor: pointer;
				transition: background 0.15s ease;
			}

			button:active {
				background-color: rgb(22, 22, 27);
			}
		</style>
	</>
}
