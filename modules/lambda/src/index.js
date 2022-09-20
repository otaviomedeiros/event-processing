exports.handler = async (event) => {
  console.log(`Batch size: ${event.Records.length}`)

  event.Records.forEach(record => {
    const { body } = record;
    console.log(`Event => ${JSON.parse(body)}`);
  })

  const response = {
      statusCode: 200,
      body: `Processed ${event.Records.length} events`,
  };
  
  return response;
};
